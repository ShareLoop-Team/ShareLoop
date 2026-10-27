// Read-only checks against the real Supabase project in ../../.env.
//
//   cd tool/db_check && npm run remote-check
//
// Never prints keys or tokens and never writes data: every request is a
// GET, an RPC that only reads, or a request that must be rejected.
//
// Optional: verify that Supabase accepts a real Firebase ID token. Set
// these in your own shell first (they are not stored anywhere):
//   SHARELOOP_TEST_EMAIL, SHARELOOP_TEST_PASSWORD  - an existing ShareLoop account
// The Firebase web API key is read from lib/firebase_options.dart, which
// `flutterfire configure` generates.

import { existsSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const FIREBASE_PROJECT = 'shareloop-c2157';

function readEnv() {
  const path = join(root, '.env');
  if (!existsSync(path)) return {};
  const env = {};
  for (const line of readFileSync(path, 'utf8').split(/\r?\n/)) {
    const match = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$/);
    if (match) env[match[1]] = match[2].replace(/^["']|["']$/g, '');
  }
  return env;
}

function jwtPayload(token) {
  try {
    return JSON.parse(Buffer.from(token.split('.')[1], 'base64url').toString('utf8'));
  } catch {
    return null;
  }
}

const env = readEnv();
const url = (env.SUPABASE_URL ?? '').replace(/\/+$/, '');
const key = env.SUPABASE_PUBLISHABLE_KEY ?? '';

if (!url) {
  console.log('SUPABASE_URL is missing from .env');
  process.exit(2);
}
if (!key) {
  console.log('SUPABASE_PUBLISHABLE_KEY is empty in .env - paste the publishable key there in your editor, then re-run.');
  process.exit(2);
}
// Refuse to use a key that must never be in the app.
if (key.startsWith('sb_secret_') || jwtPayload(key)?.role === 'service_role') {
  console.log('STOP: .env holds a SECRET / service-role key, which bypasses all security and must never ship in the app.');
  console.log('Remove it from .env, use the publishable key instead, and rotate the secret key in the Supabase dashboard.');
  process.exit(3);
}
const keyKind = key.startsWith('sb_publishable_')
  ? 'publishable key'
  : jwtPayload(key)?.role === 'anon'
    ? 'legacy anon key'
    : 'unrecognised key format';

let passed = 0;
const failures = [];
const notes = [];
const ok = (name) => { passed++; console.log(`  ok   ${name}`); };
const fail = (name, detail) => { failures.push(name); console.log(`  FAIL ${name}${detail ? ` - ${detail}` : ''}`); };

async function call(path, { method = 'GET', token, body } = {}) {
  const headers = { apikey: key, 'Content-Type': 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await fetch(`${url}${path}`, { method, headers, body: body ? JSON.stringify(body) : undefined });
  const text = await res.text();
  let json = null;
  try { json = JSON.parse(text); } catch { /* not JSON */ }
  return { status: res.status, json, text };
}

console.log(`Project: ${url}`);
console.log(`Key: ${keyKind} (value not shown)\n`);

// --- 1. Connectivity and key -------------------------------------------------
console.log('Connectivity');
const categories = await call('/rest/v1/categories?select=id&order=sort_order');
if (categories.status === 401 || categories.status === 403) {
  fail('publishable key accepted', `HTTP ${categories.status}: ${categories.json?.message ?? ''}`);
  process.exit(1);
}
ok(`project reachable and key accepted (HTTP ${categories.status})`);

// --- 2. Migration state --------------------------------------------------------
console.log('\nSchema (read-only)');
const SHARELOOP_TABLES = ['profiles', 'profile_contacts', 'categories', 'items', 'item_requests', 'exchanges', 'ratings', 'reports'];
const spec = await call('/rest/v1/');
if (spec.status === 200 && spec.json?.paths) {
  const exposed = Object.keys(spec.json.paths)
    .filter((p) => p !== '/' && !p.startsWith('/rpc/'))
    .map((p) => p.slice(1));
  const foreign = exposed.filter((t) => !SHARELOOP_TABLES.includes(t));
  console.log(`  --   tables exposed in public: ${exposed.length ? exposed.join(', ') : '(none)'}`);
  if (foreign.length) {
    notes.push(`Pre-existing tables not created by ShareLoop: ${foreign.join(', ')} - the first migration revokes anon/authenticated grants on ALL public tables; review before db push.`);
  }
} else {
  console.log(`  --   table list not available with this key (HTTP ${spec.status}); check Table Editor in the dashboard for pre-existing tables`);
}
const migrated = categories.status === 200;
if (!migrated) {
  const code = categories.json?.code;
  console.log(`  --   ShareLoop tables not found (HTTP ${categories.status}${code ? `, ${code}` : ''}): migrations have NOT been applied to this project.`);
  notes.push('Migrations are not applied; RLS checks skipped.');
} else {
  const ids = (categories.json ?? []).map((c) => c.id);
  ids.length === 7 ? ok(`categories table present with the 7 seeded categories`) : fail('seeded categories', `found ${ids.length}`);
}

// --- 3. Access without a user token ---------------------------------------------
if (migrated) {
  console.log('\nNo user token (publishable key only)');
  for (const table of ['profiles', 'profile_contacts', 'items', 'item_requests', 'exchanges', 'ratings', 'reports']) {
    const r = await call(`/rest/v1/${table}?select=*&limit=1`);
    r.status === 200 && Array.isArray(r.json) && r.json.length === 0
      ? ok(`${table}: no rows visible`)
      : fail(`${table}: no rows visible`, `HTTP ${r.status}, ${Array.isArray(r.json) ? r.json.length : '?'} rows`);
  }
  const who = await call('/rest/v1/rpc/requesting_user_id', { method: 'POST', body: {} });
  who.status === 200 && who.json === null ? ok('requesting_user_id() is null without a token') : fail('requesting_user_id() without token', `HTTP ${who.status}`);
  const write = await call('/rest/v1/rpc/create_my_profile', {
    method: 'POST',
    body: { p_display_name: 'x', p_district: 'Colombo', p_city: '', p_phone: '0770000000' },
  });
  write.status >= 400 ? ok(`profile creation refused without a token (HTTP ${write.status})`) : fail('profile creation refused without a token', `HTTP ${write.status}`);
}

// --- 4. Forged Firebase token ------------------------------------------------------
console.log('\nForged token');
const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
const now = Math.floor(Date.now() / 1000);
const forged = `${b64({ alg: 'RS256', kid: 'forged', typ: 'JWT' })}.${b64({
  iss: `https://securetoken.google.com/${FIREBASE_PROJECT}`, aud: FIREBASE_PROJECT,
  sub: 'forged-user', email: 'forged@example.com', iat: now, exp: now + 600,
})}.${Buffer.from('not-a-signature').toString('base64url')}`;
const forgedRes = await call('/rest/v1/rpc/requesting_user_id', { method: 'POST', token: forged, body: {} });
forgedRes.status === 401
  ? ok('a forged Firebase-style token is rejected (HTTP 401)')
  : fail('forged token rejected', `HTTP ${forgedRes.status}, body ${forgedRes.text.slice(0, 80)}`);

// --- 5. Real Firebase token (optional) -----------------------------------------------
const email = process.env.SHARELOOP_TEST_EMAIL;
const password = process.env.SHARELOOP_TEST_PASSWORD;
console.log('\nReal Firebase token');
if (!email || !password) {
  console.log('  --   skipped (set SHARELOOP_TEST_EMAIL and SHARELOOP_TEST_PASSWORD in your shell to run)');
  notes.push('Firebase token acceptance not tested.');
} else {
  const optionsPath = join(root, 'lib', 'firebase_options.dart');
  const options = existsSync(optionsPath) ? readFileSync(optionsPath, 'utf8') : '';
  const webBlock = options.match(/static const FirebaseOptions web = FirebaseOptions\(([\s\S]*?)\);/);
  const apiKey = webBlock?.[1].match(/apiKey:\s*'([^']+)'/)?.[1];
  if (!apiKey) {
    console.log('  --   skipped: lib/firebase_options.dart has no web config yet (run flutterfire configure)');
    notes.push('Firebase token acceptance not tested (no Firebase web config).');
  } else {
    const signIn = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    });
    const auth = await signIn.json();
    if (!auth.idToken) {
      fail('Firebase sign-in', auth.error?.message ?? `HTTP ${signIn.status}`);
    } else {
      ok('signed in to Firebase with the test account');
      const token = auth.idToken;
      const uid = auth.localId;
      const me = await call('/rest/v1/rpc/requesting_user_id', { method: 'POST', token, body: {} });
      if (me.status === 200 && me.json === uid) {
        ok('Supabase accepted the Firebase ID token and resolved the same UID');
      } else if (me.status === 401) {
        fail('Supabase accepts the Firebase ID token', 'HTTP 401 - Firebase third-party auth is probably not enabled in the Supabase dashboard');
      } else {
        fail('Supabase accepts the Firebase ID token', `HTTP ${me.status}, got ${me.json === null ? 'null (issuer/audience mismatch?)' : 'a different identity'}`);
      }

      if (migrated && me.json === uid) {
        const profile = await call(`/rest/v1/profiles?select=id&id=eq.${encodeURIComponent(uid)}`, { token });
        profile.json?.length === 1 ? ok('own profile visible') : fail('own profile visible', 'no profile row - finish registration in the app');

        const exchanges = await call('/rest/v1/exchanges?select=donor_id,requester_id,status&status=neq.cancelled', { token });
        const partners = new Set((exchanges.json ?? []).flatMap((e) => [e.donor_id, e.requester_id]));
        const contacts = await call('/rest/v1/profile_contacts?select=user_id', { token });
        const leaked = (contacts.json ?? []).filter((c) => c.user_id !== uid && !partners.has(c.user_id));
        const isAdmin = (await call(`/rest/v1/profiles?select=is_admin&id=eq.${encodeURIComponent(uid)}`, { token })).json?.[0]?.is_admin;
        isAdmin
          ? console.log('  --   test account is an admin; contact visibility check not meaningful')
          : leaked.length === 0
            ? ok('only own / exchange-partner contact details visible')
            : fail('contact details isolation', `${leaked.length} other users' contacts visible`);

        const hiddenOthers = await call(`/rest/v1/items?select=id&is_hidden=eq.true&donor_id=neq.${encodeURIComponent(uid)}`, { token });
        isAdmin || (hiddenOthers.json ?? []).length === 0
          ? ok("other donors' hidden posts not visible")
          : fail('hidden posts isolation', `${hiddenOthers.json.length} visible`);
      }
    }
  }
}

console.log(`\n${passed} passed, ${failures.length} failed`);
for (const note of notes) console.log(`note: ${note}`);
process.exit(failures.length ? 1 : 0);
