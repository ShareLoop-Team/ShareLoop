-- Minimal stand-ins for what a Supabase database provides before any
-- migration runs: API roles, auth.jwt(), the storage schema, and the
-- default grants Supabase gives anon/authenticated in `public`.
-- Only used by run.mjs; never applied to a real project.

create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;

create schema auth;
create schema extensions;
create schema storage;
grant usage on schema auth, extensions, storage, public to anon, authenticated, service_role;

-- PostgREST puts the verified token's claims in this setting.
create function auth.jwt() returns jsonb
language sql stable
as $$
  select coalesce(nullif(current_setting('request.jwt.claims', true), ''), '{}')::jsonb
$$;
grant execute on function auth.jwt() to anon, authenticated, service_role;

create table storage.buckets (
  id text primary key,
  name text not null,
  public boolean default false,
  file_size_limit bigint,
  allowed_mime_types text[]
);

create table storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text references storage.buckets (id),
  name text not null,
  owner_id text,
  created_at timestamptz default now(),
  unique (bucket_id, name)
);
alter table storage.objects enable row level security;
grant select, insert, update, delete on storage.objects to anon, authenticated, service_role;
grant select on storage.buckets to anon, authenticated, service_role;

-- Same contract as Supabase's storage.foldername(): the path's folders.
create function storage.foldername(name text) returns text[]
language plpgsql immutable
as $$
declare
  parts text[] := string_to_array(name, '/');
begin
  return parts[1:array_length(parts, 1) - 1];
end;
$$;
grant execute on function storage.foldername(text) to anon, authenticated, service_role;

alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public grant all on functions to anon, authenticated, service_role;
alter default privileges in schema public grant all on sequences to anon, authenticated, service_role;
