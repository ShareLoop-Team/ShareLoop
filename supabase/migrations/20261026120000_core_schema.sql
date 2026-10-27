-- ShareLoop core schema: profiles, categories, items, requests, exchanges,
-- ratings and reports, with Row Level Security.
--
-- Identity model
-- --------------
-- Users sign in with Firebase Authentication. Supabase's Firebase
-- third-party auth integration verifies each Firebase ID token's signature,
-- so auth.jwt() only ever holds a genuine Firebase token. Firebase signs
-- tokens for *every* Firebase project with the same keys, so every policy
-- goes through public.requesting_user_id(), which also pins the issuer and
-- audience to ShareLoop's Firebase project. Without a `role` custom claim
-- such tokens run as the `anon` Postgres role, so grants below cover both
-- `anon` and `authenticated`; a request with no Firebase token at all has
-- requesting_user_id() = null and is refused by every write policy.
--
-- Firebase UIDs are not UUIDs, so never use auth.uid() (it casts to uuid).
--
-- State changes that span several rows (selecting a requester, confirming a
-- handover, rating, moderation) are only possible through the functions in
-- the workflow migration; clients get column-level UPDATE grants for plain
-- edits and nothing else.

create extension if not exists pg_trgm with schema extensions;

create schema if not exists private;
grant usage on schema private to anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Identity helpers
-- ---------------------------------------------------------------------------

-- The Firebase UID of the caller, or null when the request carries no token
-- from ShareLoop's Firebase project.
create or replace function public.requesting_user_id()
returns text
language sql
stable
set search_path = ''
as $$
  select case
    when auth.jwt() ->> 'iss' = 'https://securetoken.google.com/shareloop-c2157'
     and auth.jwt() ->> 'aud' = 'shareloop-c2157'
     and coalesce(auth.jwt() ->> 'sub', '') <> ''
    then auth.jwt() ->> 'sub'
  end
$$;

-- ---------------------------------------------------------------------------
-- Types and domains
-- ---------------------------------------------------------------------------

create type public.item_status as enum ('active', 'pending_handover', 'completed');
create type public.request_status as enum ('pending', 'approved', 'rejected');
create type public.exchange_status as enum ('pending', 'completed', 'cancelled');
create type public.report_status as enum ('open', 'actioned', 'dismissed');
create type public.account_status as enum ('active', 'suspended');

-- Mirrors AppConstants.sriLankanDistricts in the Flutter app.
create domain public.sl_district as text check (value in (
  'Ampara', 'Anuradhapura', 'Badulla', 'Batticaloa', 'Colombo', 'Galle',
  'Gampaha', 'Hambantota', 'Jaffna', 'Kalutara', 'Kandy', 'Kegalle',
  'Kilinochchi', 'Kurunegala', 'Mannar', 'Matale', 'Matara', 'Monaragala',
  'Mullaitivu', 'Nuwara Eliya', 'Polonnaruwa', 'Puttalam', 'Ratnapura',
  'Trincomalee', 'Vavuniya'
));

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

-- Public profile of a user, readable by every signed-in user. Contact
-- details live in profile_contacts so they are only shared after a donor
-- selects a requester.
create table public.profiles (
  id text primary key check (char_length(id) between 1 and 128),
  display_name text not null check (char_length(btrim(display_name)) between 1 and 80),
  district public.sl_district not null,
  city text not null default '' check (char_length(city) <= 80),
  avatar_path text check (char_length(avatar_path) <= 300),
  donation_count integer not null default 0 check (donation_count >= 0),
  rating_avg numeric(3, 2) not null default 0 check (rating_avg between 0 and 5),
  rating_count integer not null default 0 check (rating_count >= 0),
  is_admin boolean not null default false,
  status public.account_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.profile_contacts (
  user_id text primary key references public.profiles (id) on delete cascade,
  email text not null check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$' and char_length(email) <= 254),
  phone text not null check (phone ~ '^\+?[0-9 ]{7,20}$'),
  updated_at timestamptz not null default now()
);

create table public.categories (
  id text primary key check (id ~ '^[a-z0-9_-]{1,40}$'),
  name text not null unique check (char_length(btrim(name)) between 1 and 60),
  icon_name text not null default 'category' check (char_length(icon_name) <= 40),
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- A "Give Away" post. image_paths are object names in the item-images
-- bucket, each under the donor's own folder.
create table public.items (
  id uuid primary key default gen_random_uuid(),
  donor_id text not null references public.profiles (id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 120),
  description text not null check (char_length(btrim(description)) between 1 and 2000),
  condition text not null check (condition in ('New', 'Good', 'Used')),
  category text not null references public.categories (name) on update cascade,
  district public.sl_district not null,
  city text not null default '' check (char_length(city) <= 80),
  image_paths text[] not null default '{}' check (cardinality(image_paths) <= 5),
  status public.item_status not null default 'active',
  selected_request_id uuid,
  is_hidden boolean not null default false,
  hidden_reason text check (char_length(hidden_reason) <= 500),
  search_text text generated always as (lower(title || ' ' || description)) stored,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (status <> 'active' or selected_request_id is null)
);

-- Either a standalone "need" post (item_id null) or a request for a
-- specific give-away item.
create table public.item_requests (
  id uuid primary key default gen_random_uuid(),
  requester_id text not null references public.profiles (id) on delete cascade,
  item_id uuid references public.items (id) on delete cascade,
  item_name text not null default '' check (char_length(item_name) <= 120),
  description text not null check (char_length(btrim(description)) between 1 and 2000),
  reason text not null check (char_length(btrim(reason)) between 1 and 1000),
  notes text not null default '' check (char_length(notes) <= 1000),
  category text not null references public.categories (name) on update cascade,
  district public.sl_district not null,
  city text not null default '' check (char_length(city) <= 80),
  status public.request_status not null default 'pending',
  is_hidden boolean not null default false,
  search_text text generated always as (lower(item_name || ' ' || description || ' ' || reason)) stored,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (item_id is not null or char_length(btrim(item_name)) > 0)
);

alter table public.items
  add constraint items_selected_request_id_fkey
  foreign key (selected_request_id) references public.item_requests (id) on delete set null;

-- The handover between a donor and the requester they selected. Completed
-- only once both parties have confirmed. Kept (with a title snapshot) if
-- the item or request is later deleted, so donation counts and ratings
-- keep their history.
create table public.exchanges (
  id uuid primary key default gen_random_uuid(),
  item_id uuid references public.items (id) on delete set null,
  request_id uuid references public.item_requests (id) on delete set null,
  item_title text not null,
  donor_id text not null references public.profiles (id) on delete cascade,
  requester_id text not null references public.profiles (id) on delete cascade,
  status public.exchange_status not null default 'pending',
  donor_confirmed_at timestamptz,
  requester_confirmed_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz,
  cancelled_by text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (donor_id <> requester_id),
  check (status <> 'completed' or (
    donor_confirmed_at is not null and requester_confirmed_at is not null and completed_at is not null
  )),
  check (status <> 'cancelled' or cancelled_at is not null)
);

create table public.ratings (
  id uuid primary key default gen_random_uuid(),
  exchange_id uuid not null references public.exchanges (id) on delete cascade,
  item_id uuid references public.items (id) on delete set null,
  rater_id text not null references public.profiles (id) on delete cascade,
  ratee_id text not null references public.profiles (id) on delete cascade,
  stars smallint not null check (stars between 1 and 5),
  comment text not null default '' check (char_length(comment) <= 1000),
  created_at timestamptz not null default now(),
  unique (exchange_id, rater_id),
  check (rater_id <> ratee_id)
);

-- A user's report of an inappropriate post, request or user, for admins.
create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id text not null references public.profiles (id) on delete cascade,
  item_id uuid references public.items (id) on delete cascade,
  request_id uuid references public.item_requests (id) on delete cascade,
  reported_user_id text references public.profiles (id) on delete cascade,
  reason text not null check (reason in ('spam', 'inappropriate', 'prohibited_item', 'scam', 'other')),
  details text not null default '' check (char_length(details) <= 1000),
  status public.report_status not null default 'open',
  resolved_by text references public.profiles (id) on delete set null,
  resolved_at timestamptz,
  resolution_note text check (char_length(resolution_note) <= 1000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (num_nonnulls(item_id, request_id, reported_user_id) = 1)
);

-- ---------------------------------------------------------------------------
-- Indexes (feeds are newest-first; ties broken by id for stable paging)
-- ---------------------------------------------------------------------------

create index items_feed_idx on public.items (created_at desc, id desc) where not is_hidden;
create index items_donor_idx on public.items (donor_id, created_at desc);
create index items_category_idx on public.items (category, created_at desc) where not is_hidden;
create index items_district_idx on public.items (district, created_at desc) where not is_hidden;
create index items_search_idx on public.items using gin (search_text extensions.gin_trgm_ops);
create index items_selected_request_idx on public.items (selected_request_id);

create index item_requests_feed_idx on public.item_requests (created_at desc, id desc) where not is_hidden;
create index item_requests_item_idx on public.item_requests (item_id, created_at desc);
create index item_requests_requester_idx on public.item_requests (requester_id, created_at desc);
create index item_requests_search_idx on public.item_requests using gin (search_text extensions.gin_trgm_ops);
-- One request per requester per give-away item.
create unique index item_requests_one_per_item_idx
  on public.item_requests (requester_id, item_id) where item_id is not null;

-- At most one live (pending or completed) exchange per item and request.
create unique index exchanges_live_item_idx on public.exchanges (item_id) where status <> 'cancelled';
create unique index exchanges_live_request_idx on public.exchanges (request_id) where status <> 'cancelled';
create index exchanges_donor_idx on public.exchanges (donor_id, created_at desc);
create index exchanges_requester_idx on public.exchanges (requester_id, created_at desc);

create index ratings_ratee_idx on public.ratings (ratee_id, created_at desc);
create index ratings_rater_idx on public.ratings (rater_id);
create index ratings_item_idx on public.ratings (item_id);

create index reports_status_idx on public.reports (status, created_at desc);
create index reports_reporter_idx on public.reports (reporter_id);
create index reports_item_idx on public.reports (item_id);
create index reports_request_idx on public.reports (request_id);
create index reports_user_idx on public.reports (reported_user_id);
create index reports_resolved_by_idx on public.reports (resolved_by);
-- One open report per reporter per target.
create unique index reports_one_open_idx
  on public.reports (reporter_id, item_id, request_id, reported_user_id) nulls not distinct
  where status = 'open';

-- ---------------------------------------------------------------------------
-- Private helpers (not exposed through the API)
-- ---------------------------------------------------------------------------

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = public.requesting_user_id() and is_admin and status = 'active'
  )
$$;

-- Signed in with a profile that has not been suspended: required to write.
create or replace function private.is_active_user()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = public.requesting_user_id() and status = 'active'
  )
$$;

-- Whether the caller and [other] are the two parties of a live exchange.
create or replace function private.shares_exchange_with(other text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.exchanges e
    where e.status <> 'cancelled'
      and ((e.donor_id = public.requesting_user_id() and e.requester_id = other)
        or (e.requester_id = public.requesting_user_id() and e.donor_id = other))
  )
$$;

create or replace function private.owns_item(p_item_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.items
    where id = p_item_id and donor_id = public.requesting_user_id()
  )
$$;

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------

create or replace function private.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger profiles_touch before update on public.profiles
  for each row execute function private.touch_updated_at();
create trigger profile_contacts_touch before update on public.profile_contacts
  for each row execute function private.touch_updated_at();
create trigger items_touch before update on public.items
  for each row execute function private.touch_updated_at();
create trigger item_requests_touch before update on public.item_requests
  for each row execute function private.touch_updated_at();
create trigger exchanges_touch before update on public.exchanges
  for each row execute function private.touch_updated_at();
create trigger reports_touch before update on public.reports
  for each row execute function private.touch_updated_at();

-- Item photos must live in the donor's own storage folder, so a post can
-- never reference (and later delete) someone else's upload.
create or replace function private.check_item_image_paths()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  path text;
begin
  foreach path in array new.image_paths loop
    if path is null or path not like new.donor_id || '/%' or path like '%..%' then
      raise exception 'Image path % is not in the donor''s folder', path
        using errcode = 'check_violation';
    end if;
  end loop;
  return new;
end;
$$;

create trigger items_check_image_paths before insert or update of image_paths, donor_id
  on public.items for each row execute function private.check_item_image_paths();

-- A request for a give-away item must target a visible, still-available
-- item that belongs to someone else.
create or replace function private.check_item_request_target()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.items%rowtype;
begin
  if new.item_id is null then
    return new;
  end if;
  select * into target from public.items where id = new.item_id;
  if not found or target.is_hidden then
    raise exception 'Item not found' using errcode = 'foreign_key_violation';
  end if;
  if target.donor_id = new.requester_id then
    raise exception 'You cannot request your own item' using errcode = 'check_violation';
  end if;
  if target.status <> 'active' then
    raise exception 'This item is no longer available' using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

create trigger item_requests_check_target before insert on public.item_requests
  for each row execute function private.check_item_request_target();

-- Keeps profiles.rating_avg/rating_count in step with ratings.
create or replace function private.refresh_rating_summary()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target text := coalesce(new.ratee_id, old.ratee_id);
begin
  update public.profiles p
  set rating_count = s.n,
      rating_avg = coalesce(round(s.avg_stars, 2), 0)
  from (
    select count(*)::integer as n, avg(stars) as avg_stars
    from public.ratings where ratee_id = target
  ) s
  where p.id = target;
  return null;
end;
$$;

create trigger ratings_refresh_summary after insert or delete on public.ratings
  for each row execute function private.refresh_rating_summary();

-- ---------------------------------------------------------------------------
-- Grants
--
-- Supabase grants everything in `public` to anon/authenticated by default;
-- replace that with the minimum each table needs. Firebase tokens without a
-- `role` claim run as anon, so both roles get the same grants and RLS does
-- the real work.
-- ---------------------------------------------------------------------------

revoke all on all tables in schema public from anon, authenticated;
revoke all on all functions in schema private from public, anon, authenticated;
grant execute on function private.is_admin() to anon, authenticated;
grant execute on function private.is_active_user() to anon, authenticated;
grant execute on function private.shares_exchange_with(text) to anon, authenticated;
grant execute on function private.owns_item(uuid) to anon, authenticated;

-- Profiles are created by public.create_my_profile() (workflow migration),
-- which writes both rows at once and takes the email from the verified
-- token, so there are no INSERT grants here.
grant select on public.profiles to anon, authenticated;
grant update (display_name, district, city, avatar_path) on public.profiles to anon, authenticated;

grant select on public.profile_contacts to anon, authenticated;
grant update (phone) on public.profile_contacts to anon, authenticated;

grant select, insert, update, delete on public.categories to anon, authenticated;

grant select, delete on public.items to anon, authenticated;
grant insert (donor_id, title, description, condition, category, district, city, image_paths)
  on public.items to anon, authenticated;
grant update (title, description, condition, category, district, city, image_paths)
  on public.items to anon, authenticated;

grant select, delete on public.item_requests to anon, authenticated;
grant insert (requester_id, item_id, item_name, description, reason, notes, category, district, city)
  on public.item_requests to anon, authenticated;
grant update (item_name, description, reason, notes, category, district, city)
  on public.item_requests to anon, authenticated;

grant select on public.exchanges to anon, authenticated;
grant select on public.ratings to anon, authenticated;

grant select on public.reports to anon, authenticated;
grant insert (reporter_id, item_id, request_id, reported_user_id, reason, details)
  on public.reports to anon, authenticated;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.profile_contacts enable row level security;
alter table public.categories enable row level security;
alter table public.items enable row level security;
alter table public.item_requests enable row level security;
alter table public.exchanges enable row level security;
alter table public.ratings enable row level security;
alter table public.reports enable row level security;

-- profiles
create policy "Signed-in users can view profiles" on public.profiles
  for select to anon, authenticated
  using ((select public.requesting_user_id()) is not null);

create policy "Active users edit their own profile" on public.profiles
  for update to anon, authenticated
  using (id = (select public.requesting_user_id()) and status = 'active')
  with check (id = (select public.requesting_user_id()));

-- profile_contacts: yourself, an admin, or the other party of a live exchange
create policy "Contacts visible to self, admins and exchange partners" on public.profile_contacts
  for select to anon, authenticated
  using (
    user_id = (select public.requesting_user_id())
    or (select private.is_admin())
    or private.shares_exchange_with(user_id)
  );

create policy "Users edit their own contact details" on public.profile_contacts
  for update to anon, authenticated
  using (user_id = (select public.requesting_user_id()))
  with check (user_id = (select public.requesting_user_id()));

-- categories: reference data anyone may read; only admins change it
create policy "Anyone can view active categories" on public.categories
  for select to anon, authenticated
  using (is_active or (select private.is_admin()));

create policy "Admins add categories" on public.categories
  for insert to anon, authenticated
  with check ((select private.is_admin()));

create policy "Admins edit categories" on public.categories
  for update to anon, authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));

create policy "Admins delete categories" on public.categories
  for delete to anon, authenticated
  using ((select private.is_admin()));

-- items
create policy "Signed-in users view visible items" on public.items
  for select to anon, authenticated
  using (
    (select public.requesting_user_id()) is not null
    and (not is_hidden
      or donor_id = (select public.requesting_user_id())
      or (select private.is_admin()))
  );

create policy "Active users post items as themselves" on public.items
  for insert to anon, authenticated
  with check (
    donor_id = (select public.requesting_user_id())
    and (select private.is_active_user())
  );

create policy "Donors edit their own items" on public.items
  for update to anon, authenticated
  using (
    donor_id = (select public.requesting_user_id())
    and (select private.is_active_user())
    and status <> 'completed'
  )
  with check (donor_id = (select public.requesting_user_id()));

-- Not while a handover is underway (mirrors ItemController.canDeletePost).
create policy "Donors delete their own items unless handover is underway" on public.items
  for delete to anon, authenticated
  using (
    (donor_id = (select public.requesting_user_id()) and status <> 'pending_handover')
    or (select private.is_admin())
  );

-- item_requests: standalone needs are public to signed-in users; requests
-- for a specific item are private to the requester and that item's donor.
create policy "View public needs, own requests and requests on own items" on public.item_requests
  for select to anon, authenticated
  using (
    (select public.requesting_user_id()) is not null
    and (
      (item_id is null and not is_hidden)
      or requester_id = (select public.requesting_user_id())
      or private.owns_item(item_id)
      or (select private.is_admin())
    )
  );

create policy "Active users request as themselves" on public.item_requests
  for insert to anon, authenticated
  with check (
    requester_id = (select public.requesting_user_id())
    and (select private.is_active_user())
    and status = 'pending'
  );

create policy "Requesters edit their own pending requests" on public.item_requests
  for update to anon, authenticated
  using (
    requester_id = (select public.requesting_user_id())
    and (select private.is_active_user())
    and status = 'pending'
  )
  with check (requester_id = (select public.requesting_user_id()));

create policy "Requesters delete their own requests unless approved" on public.item_requests
  for delete to anon, authenticated
  using (
    (requester_id = (select public.requesting_user_id()) and status <> 'approved')
    or (select private.is_admin())
  );

-- exchanges: written only by workflow functions
create policy "Parties and admins view exchanges" on public.exchanges
  for select to anon, authenticated
  using (
    donor_id = (select public.requesting_user_id())
    or requester_id = (select public.requesting_user_id())
    or (select private.is_admin())
  );

-- ratings: public reviews; written only by submit_rating()
create policy "Signed-in users view ratings" on public.ratings
  for select to anon, authenticated
  using ((select public.requesting_user_id()) is not null);

-- reports
create policy "Reporters and admins view reports" on public.reports
  for select to anon, authenticated
  using (
    reporter_id = (select public.requesting_user_id())
    or (select private.is_admin())
  );

create policy "Active users file reports as themselves" on public.reports
  for insert to anon, authenticated
  with check (
    reporter_id = (select public.requesting_user_id())
    and (select private.is_active_user())
  );

-- ---------------------------------------------------------------------------
-- Reference data (mirrors AppConstants.itemCategories)
-- ---------------------------------------------------------------------------

insert into public.categories (id, name, icon_name, sort_order) values
  ('books', 'Educational Books', 'book', 10),
  ('supplies', 'School Supplies', 'edit', 20),
  ('clothes', 'Clothes', 'checkroom', 30),
  ('shoes', 'Shoes', 'sports_soccer', 40),
  ('electronics', 'Electronics', 'devices', 50),
  ('household', 'Household Items', 'chair', 60),
  ('other', 'Other', 'category', 70)
on conflict (id) do nothing;
