// Applies supabase/migrations to an in-memory Postgres (PGlite) and checks
// the access rules by acting as different Firebase users, the way
// PostgREST would: role `anon` plus the verified token's claims.
//
//   cd tool/db_check && npm install && npm test

import { readFileSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { PGlite } from '@electric-sql/pglite';
import { pg_trgm } from '@electric-sql/pglite/contrib/pg_trgm';

const here = dirname(fileURLToPath(import.meta.url));
const migrationsDir = join(here, '..', '..', 'supabase', 'migrations');
const FIREBASE_PROJECT = 'shareloop-c2157';

const db = new PGlite({ extensions: { pg_trgm } });

let passed = 0;
const failures = [];

function claimsFor(uid, project = FIREBASE_PROJECT) {
  return JSON.stringify({
    iss: `https://securetoken.google.com/${project}`,
    aud: project,
    sub: uid,
    email: `${uid}@example.com`,
    exp: 4102444800,
  });
}

/** Switches the session to role anon carrying [claims] (null = no token). */
async function actAs(claims) {
  await db.exec('reset role');
  await db.query("select set_config('request.jwt.claims', $1, false)", [claims ?? '']);
  await db.exec('set role anon');
}

const as = (uid) => actAs(uid == null ? null : claimsFor(uid));

async function asSuperuser() {
  await db.exec('reset role');
  await db.query("select set_config('request.jwt.claims', '', false)");
}

async function q(sql, params = []) {
  return (await db.query(sql, params)).rows;
}

async function expectOk(name, fn) {
  try {
    await fn();
    passed++;
  } catch (e) {
    failures.push(`${name}: unexpected error: ${e.message}`);
  }
}

async function expectError(name, fn, pattern) {
  try {
    await fn();
    failures.push(`${name}: expected an error matching ${pattern}`);
  } catch (e) {
    if (pattern && !pattern.test(e.message)) {
      failures.push(`${name}: error "${e.message}" did not match ${pattern}`);
    } else {
      passed++;
    }
  }
}

async function expectEqual(name, actual, expected) {
  const a = JSON.stringify(actual);
  const b = JSON.stringify(expected);
  if (a === b) passed++;
  else failures.push(`${name}: expected ${b}, got ${a}`);
}

const DENIED = /row-level security|permission denied/;

// --- Apply schema ----------------------------------------------------------

await db.exec(readFileSync(join(here, 'supabase_stubs.sql'), 'utf8'));
for (const file of readdirSync(migrationsDir).filter((f) => f.endsWith('.sql')).sort()) {
  try {
    await db.exec(readFileSync(join(migrationsDir, file), 'utf8'));
    console.log(`applied ${file}`);
  } catch (e) {
    console.error(`FAILED to apply ${file}: ${e.message}`);
    process.exit(1);
  }
}

// --- Identity and profiles ---------------------------------------------------

const profile = (name, district = 'Colombo', phone = '0771234567') =>
  q("select create_my_profile($1, $2, 'Nugegoda', $3)", [name, district, phone]);

await as(null);
await expectEqual('no token: cannot list profiles', (await q('select * from profiles')).length, 0);
await expectError('no token: cannot create a profile', () => profile('Ghost'), /Not signed in/);
await expectEqual('no token: categories are readable', (await q('select * from categories')).length, 7);

await actAs(claimsFor('alice', 'some-other-firebase-project'));
await expectError('token from another Firebase project is refused', () => profile('Alice'), /Not signed in/);

await as('alice');
await expectError('profiles cannot be inserted directly (e.g. as admin)',
  () => q("insert into profiles (id, display_name, district, is_admin) values ('alice', 'A', 'Colombo', true)"),
  /permission denied/);
await expectError('district must be a Sri Lankan district', () => profile('Alice', 'Atlantis'), /check|violates/);
await expectError('phone number is validated', () => profile('Alice', 'Colombo', 'call me'), /check/);
await expectOk('alice creates her profile', () => profile('Alice'));
await expectError('a second profile is refused', () => profile('Alice again'), /duplicate key/);
await expectEqual('contact email comes from the verified token',
  (await q("select email from profile_contacts where user_id = 'alice'"))[0].email, 'alice@example.com');
await expectError('cannot change the token-backed email',
  () => q("update profile_contacts set email = 'evil@example.com' where user_id = 'alice'"), /permission denied/);
await expectError('cannot raise own donation count',
  () => q("update profiles set donation_count = 99 where id = 'alice'"), /permission denied/);
await expectError('cannot promote self to admin',
  () => q("update profiles set is_admin = true where id = 'alice'"), /permission denied/);
await expectOk('alice edits her profile', () => q("update profiles set city = 'Maharagama' where id = 'alice'"));

for (const name of ['Bob', 'Carol', 'Admin']) {
  await as(name.toLowerCase());
  await profile(name);
}
await asSuperuser();
await q("update profiles set is_admin = true where id = 'admin'");

await as('bob');
await expectEqual('bob sees all public profiles', (await q('select id from profiles')).length, 4);
await expectEqual('bob cannot see alice\'s phone', (await q("select * from profile_contacts where user_id = 'alice'")).length, 0);
await expectEqual('bob updating alice\'s profile changes nothing',
  (await q("update profiles set city = 'X' where id = 'alice' returning id")).length, 0);

// --- Items ---------------------------------------------------------------------

const postItem = (donor, title, images = []) =>
  q(`insert into items (donor_id, title, description, condition, category, district, city, image_paths)
     values ($1, $2, 'Works fine', 'Good', 'Electronics', 'Colombo', 'Nugegoda', $3) returning id`,
    [donor, title, images]);

await as('alice');
let lampId;
await expectOk('alice posts an item with her own photo', async () => {
  lampId = (await postItem('alice', 'Desk lamp', ['alice/lamp.jpg']))[0].id;
});
await expectError('photo outside the donor\'s folder is refused', () => postItem('alice', 'Fan', ['bob/fan.jpg']), /donor's folder/);
await expectError('path traversal in photo path is refused', () => postItem('alice', 'Fan', ['alice/../bob/fan.jpg']), /donor's folder/);
await expectError('unknown category is refused',
  () => q("insert into items (donor_id, title, description, condition, category, district) values ('alice', 'T', 'D', 'Good', 'Weapons', 'Colombo')"),
  /foreign key/);
await expectError('donor cannot set status directly',
  () => q("update items set status = 'completed' where id = $1", [lampId]), /permission denied/);

await as('bob');
await expectError('bob cannot post as alice', () => postItem('alice', 'Fake'), DENIED);
await expectEqual('bob sees alice\'s item', (await q('select id from items')).length, 1);
await expectEqual('search finds the item', (await q("select id from items where search_text ilike '%lamp%'")).length, 1);
await expectEqual('bob cannot delete alice\'s item', (await q('delete from items where id = $1 returning id', [lampId])).length, 0);

// --- Requests ------------------------------------------------------------------

const request = (uid, itemId, itemName = '') =>
  q(`insert into item_requests (requester_id, item_id, item_name, description, reason, category, district)
     values ($1, $2, $3, 'Need it', 'For studying', 'Electronics', 'Gampaha') returning id`, [uid, itemId, itemName]);

let bobRequestId;
let carolRequestId;
await expectOk('bob requests alice\'s item', async () => {
  bobRequestId = (await request('bob', lampId))[0].id;
});
await expectError('bob cannot request the same item twice', () => request('bob', lampId), /duplicate key/);
await expectError('bob cannot request as carol', () => request('carol', lampId), DENIED);
await expectOk('bob posts a standalone need', () => request('bob', null, 'Calculator'));
await expectError('a standalone need must name the item', () => request('bob', null, ''), /check/);
await expectError('bob cannot approve his own request',
  () => q("update item_requests set status = 'approved' where id = $1", [bobRequestId]), /permission denied/);

await as('alice');
await expectError('alice cannot request her own item', () => request('alice', lampId), /own item/);
await expectEqual('alice sees requests on her item', (await q('select id from item_requests where item_id = $1', [lampId])).length, 1);

await as('carol');
await expectOk('carol requests the item', async () => {
  carolRequestId = (await request('carol', lampId))[0].id;
});
await expectEqual('carol sees only her own request on the item, plus public needs',
  (await q('select requester_id, item_id is null as standalone from item_requests order by requester_id')).map((r) => [r.requester_id, r.standalone]),
  [['bob', true], ['carol', false]]);

// --- Exchange workflow -------------------------------------------------------------

await as('bob');
await expectError('only the donor can select a requester', () => q('select select_requester($1)', [bobRequestId]), /Only the donor/);

await as('alice');
await expectOk('alice selects bob', () => q('select select_requester($1)', [bobRequestId]));
await expectEqual('item is pending handover', (await q('select status from items where id = $1', [lampId]))[0].status, 'pending_handover');
await expectError('cannot select a second requester', () => q('select select_requester($1)', [carolRequestId]), /no longer available/);
await expectEqual('alice now sees bob\'s phone', (await q("select phone from profile_contacts where user_id = 'bob'")).length, 1);
await expectEqual('alice cannot delete the item mid-handover', (await q('delete from items where id = $1 returning id', [lampId])).length, 0);

await as('bob');
await expectEqual('bob now sees alice\'s phone', (await q("select phone from profile_contacts where user_id = 'alice'")).length, 1);
await expectError('bob cannot rate before confirming', () => q('select submit_rating($1, 5)', [lampId]), /Confirm the handover/);
await expectEqual('requester cannot delete an approved request', (await q('delete from item_requests where id = $1 returning id', [bobRequestId])).length, 0);

await as('carol');
await expectEqual('carol cannot see alice\'s phone', (await q("select * from profile_contacts where user_id = 'alice'")).length, 0);
await expectError('carol cannot confirm someone else\'s handover', () => q('select confirm_handover($1)', [lampId]), /not part/);

await as('alice');
await expectEqual('donor confirmation alone does not complete',
  (await q('select (confirm_handover($1)).status', [lampId]))[0].status, 'pending');
await expectEqual('confirming twice is harmless',
  (await q('select (confirm_handover($1)).status', [lampId]))[0].status, 'pending');
await expectOk('alice rates bob after confirming', () => q("select submit_rating($1, 4, 'On time')", [lampId]));

await as('bob');
await expectEqual('requester confirmation completes the exchange',
  (await q('select (confirm_handover($1)).status', [lampId]))[0].status, 'completed');
await expectOk('bob rates alice', () => q("select submit_rating($1, 5, 'Very kind')", [lampId]));
await expectError('bob cannot rate twice', () => q('select submit_rating($1, 1)', [lampId]), /already rated/);
await expectError('stars must be 1-5', async () => {
  await asSuperuser();
  await q("delete from ratings where rater_id = 'bob'");
  await as('bob');
  await q('select submit_rating($1, 9)', [lampId]);
}, /check/);
await q("select submit_rating($1, 5, 'Very kind')", [lampId]);

await as('carol');
await expectEqual('item is completed', (await q('select status from items where id = $1', [lampId]))[0].status, 'completed');
await expectEqual('alice\'s donation count went up',
  (await q("select donation_count, rating_avg::text, rating_count from profiles where id = 'alice'"))[0],
  { donation_count: 1, rating_avg: '5.00', rating_count: 1 });
await expectEqual('carol\'s request was declined', (await q('select status from item_requests where id = $1', [carolRequestId]))[0].status, 'rejected');
await expectError('carol cannot rate this exchange', () => q('select submit_rating($1, 1)', [lampId]), /Confirm the handover/);
await expectEqual('carol cannot see the exchange', (await q('select * from exchanges')).length, 0);

// Cancelling puts the item back on offer. Dave has no other exchange with
// alice, so their contact sharing depends on this one alone.
await as('dave');
await profile('Dave');
await as('alice');
const fanId = (await postItem('alice', 'Table fan'))[0].id;
await as('dave');
const fanRequestId = (await request('dave', fanId))[0].id;
await as('alice');
await q('select select_requester($1)', [fanRequestId]);
await expectEqual('contacts are shared while the handover is pending',
  (await q("select * from profile_contacts where user_id = 'dave'")).length, 1);
await as('dave');
await expectEqual('requester can cancel', (await q('select (cancel_exchange($1)).status', [fanId]))[0].status, 'cancelled');
await expectEqual('cancelled request is declined', (await q('select status from item_requests where id = $1', [fanRequestId]))[0].status, 'rejected');
await as('alice');
await expectEqual('item is active again after cancel',
  (await q('select status, selected_request_id from items where id = $1', [fanId]))[0], { status: 'active', selected_request_id: null });
await expectEqual('contacts are no longer shared after cancel',
  (await q("select * from profile_contacts where user_id = 'dave'")).length, 0);
await expectEqual('donor can delete an item that is active again', (await q('delete from items where id = $1 returning id', [fanId])).length, 1);

// --- Moderation --------------------------------------------------------------------

await as('bob');
await expectOk('bob reports an item', () => q("insert into reports (reporter_id, item_id, reason) values ('bob', $1, 'spam')", [lampId]));
await expectError('bob cannot file the same open report twice',
  () => q("insert into reports (reporter_id, item_id, reason) values ('bob', $1, 'spam')", [lampId]), /duplicate key/);
await expectError('a report needs exactly one target',
  () => q("insert into reports (reporter_id, item_id, reported_user_id, reason) values ('bob', $1, 'alice', 'spam')", [lampId]), /check/);
await expectError('bob cannot hide items', () => q('select admin_set_item_hidden($1, true)', [lampId]), /Admins only/);
await expectError('bob cannot add categories',
  () => q("insert into categories (id, name) values ('toys', 'Toys')"), DENIED);

await as('carol');
await expectEqual('carol cannot see bob\'s report', (await q('select * from reports')).length, 0);

await as('admin');
await expectEqual('admin sees reports', (await q('select * from reports')).length, 1);
await expectOk('admin hides the item', () => q("select admin_set_item_hidden($1, true, 'Spam')", [lampId]));
await expectOk('admin resolves the report',
  () => q("select admin_resolve_report(id, 'actioned', 'Hidden') from reports"));
await expectOk('admin adds a category', () => q("insert into categories (id, name, icon_name) values ('toys', 'Toys', 'toys')"));
await expectOk('admin suspends carol', () => q("select admin_set_user_status('carol', 'suspended')"));
await expectError('admin cannot suspend themselves', () => q("select admin_set_user_status('admin', 'suspended')"), /own account/);
await expectEqual('admin can read any contact details', (await q('select user_id from profile_contacts')).length, 5);

await as('bob');
await expectEqual('hidden item is gone for other users', (await q('select id from items where id = $1', [lampId])).length, 0);
await as('alice');
await expectEqual('donor still sees their hidden item', (await q('select is_hidden from items where id = $1', [lampId])).length, 1);
await as('carol');
await expectError('suspended user cannot post', () => postItem('carol', 'Chair'), DENIED);
await expectError('suspended user cannot use workflow functions', () => q('select confirm_handover($1)', [lampId]), /not active/);

// --- Storage -------------------------------------------------------------------------

const upload = (name) => q("insert into storage.objects (bucket_id, name, owner_id) values ('item-images', $1, current_setting('request.jwt.claims', true)::jsonb ->> 'sub')", [name]);

await as('bob');
await expectOk('bob uploads into his folder', () => upload('bob/photo1.jpg'));
await expectError('bob cannot upload into alice\'s folder', () => upload('alice/photo1.jpg'), DENIED);
await expectError('bob cannot upload at the bucket root', () => upload('photo1.jpg'), DENIED);
await as('alice');
await expectEqual('signed-in users can read item images', (await q('select name from storage.objects')).length, 1);
await expectEqual('alice cannot delete bob\'s photo',
  (await q("delete from storage.objects where name = 'bob/photo1.jpg' returning name")).length, 0);
await expectEqual('alice cannot overwrite bob\'s photo',
  (await q("update storage.objects set owner_id = 'alice' where name = 'bob/photo1.jpg' returning name")).length, 0);
await expectError('alice cannot move a photo into bob\'s folder', async () => {
  await upload('alice/move.jpg');
  await q("update storage.objects set name = 'bob/move.jpg' where name = 'alice/move.jpg'");
}, DENIED);
await as(null);
await expectEqual('no token: cannot read item images', (await q('select name from storage.objects')).length, 0);
await as('carol');
await expectError('suspended user cannot upload', () => upload('carol/x.jpg'), DENIED);
await as('admin');
await expectEqual('admin can delete any item image',
  (await q("delete from storage.objects where name = 'bob/photo1.jpg' returning name")).length, 1);

// --- Report --------------------------------------------------------------------------

console.log(`\n${passed} checks passed, ${failures.length} failed`);
for (const f of failures) console.log(`  FAIL ${f}`);
process.exit(failures.length ? 1 : 0);
