-- Synthetic Supabase interfaces for an isolated in-memory Postgres engine.
-- This is NOT a replacement for Supabase GoTrue/Storage integration tests.
create role anon;
create role authenticated;
create role service_role bypassrls;
create schema auth;
create schema storage;
create schema extensions;
create table auth.users (
 id uuid primary key, email text, raw_app_meta_data jsonb not null default '{}',
 email_confirmed_at timestamptz, deleted_at timestamptz, banned_until timestamptz
);
create table auth.sessions (
 id uuid primary key, user_id uuid not null references auth.users(id) on delete cascade,
 not_after timestamptz
);
create table auth.identities (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade
);
create table auth.refresh_tokens (
 id uuid primary key default gen_random_uuid(), user_id text,
 session_id uuid references auth.sessions(id) on delete cascade
);
create table auth.flow_state (
 id uuid primary key default gen_random_uuid(), user_id uuid
);
create function auth.jwt() returns jsonb language sql stable as $$
 select coalesce(nullif(current_setting('request.jwt.claims',true),'')::jsonb,'{}'::jsonb);
$$;
create function auth.uid() returns uuid language sql stable as $$
 select (auth.jwt()->>'sub')::uuid;
$$;
grant usage on schema auth,storage to anon,authenticated,service_role;
grant execute on function auth.jwt(),auth.uid() to anon,authenticated,service_role;
create table storage.buckets (
 id text primary key, name text, public boolean default false,
 owner uuid references auth.users(id), owner_id text
);
create table storage.objects (
 id uuid primary key default gen_random_uuid(),
 bucket_id text references storage.buckets(id), name text,
 owner uuid references auth.users(id), owner_id text
);
alter table storage.objects enable row level security;
create function storage.foldername(name text) returns text[] language sql immutable as $$
 select (string_to_array(name,'/'))[1:array_length(string_to_array(name,'/'),1)-1];
$$;
grant all on all tables in schema storage to anon,authenticated,service_role;
grant usage on schema public to anon,authenticated,service_role;
alter default privileges in schema public grant all on tables to anon,authenticated,service_role;
alter default privileges in schema public grant all on sequences to anon,authenticated,service_role;
alter default privileges in schema public grant execute on functions to anon,authenticated,service_role;
