-- Marebook · Supabase schema
-- Barns hold everything. Members of a barn share its records; roles limit writes.
-- Stallion listings are readable by everyone so Stallion Search works across barns.

create extension if not exists pgcrypto;

create table if not exists public.barns (
  id uuid primary key default gen_random_uuid(),
  name text not null default 'My barn',
  join_code text unique not null default upper(substr(encode(gen_random_bytes(6), 'hex'), 1, 6)),
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.barn_members (
  barn_id uuid not null references public.barns(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'Staff' check (role in ('Owner','Barn manager','Staff','Vet','Trainer','Viewer')),
  display_name text,
  email text,
  created_at timestamptz not null default now(),
  primary key (barn_id, user_id)
);
create index if not exists barn_members_user on public.barn_members(user_id);

-- Every record in the app (mares, foals, stallions, tasks, costs, settings…) is one row.
create table if not exists public.docs (
  barn_id uuid not null references public.barns(id) on delete cascade,
  coll text not null,
  id text not null,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid default auth.uid(),
  primary key (barn_id, coll, id)
);
create index if not exists docs_coll on public.docs(coll);
alter table public.docs replica identity full;

-- Public sign-ups and Contact us messages.
create table if not exists public.signups (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('member','inquiry')),
  data jsonb not null,
  created_at timestamptz not null default now()
);

create table if not exists public.site_admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

-- ---------- helpers ----------
create or replace function public.is_member(b uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from barn_members where barn_id = b and user_id = auth.uid());
$$;
create or replace function public.can_write(b uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from barn_members where barn_id = b and user_id = auth.uid() and role <> 'Viewer');
$$;
create or replace function public.is_owner(b uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from barn_members where barn_id = b and user_id = auth.uid() and role = 'Owner');
$$;
create or replace function public.is_site_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from site_admins where user_id = auth.uid());
$$;

-- Create a barn and make the caller its owner.
create or replace function public.create_barn(barn_name text) returns uuid
language plpgsql security definer set search_path = public as $$
declare b uuid; u auth.users%rowtype;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  select * into u from auth.users where id = auth.uid();
  insert into barns(name, created_by) values (coalesce(nullif(trim(barn_name), ''), 'My barn'), auth.uid()) returning id into b;
  insert into barn_members(barn_id, user_id, role, display_name, email)
    values (b, auth.uid(), 'Owner', coalesce(u.raw_user_meta_data->>'contact', split_part(u.email, '@', 1)), u.email);
  return b;
end $$;

-- Join a barn with its 6-character code.
create or replace function public.join_barn(code text) returns uuid
language plpgsql security definer set search_path = public as $$
declare b uuid; u auth.users%rowtype;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  select id into b from barns where join_code = upper(trim(code));
  if b is null then raise exception 'No barn with that code'; end if;
  select * into u from auth.users where id = auth.uid();
  insert into barn_members(barn_id, user_id, role, display_name, email)
    values (b, auth.uid(), 'Staff', coalesce(u.raw_user_meta_data->>'contact', split_part(u.email, '@', 1)), u.email)
    on conflict (barn_id, user_id) do nothing;
  return b;
end $$;

-- Owners set roles (Viewer = read only).
create or replace function public.set_member_role(b uuid, member uuid, new_role text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_owner(b) then raise exception 'Only the barn owner can change roles'; end if;
  if member = auth.uid() and new_role <> 'Owner' and (select count(*) from barn_members where barn_id = b and role = 'Owner') < 2 then
    raise exception 'A barn needs at least one owner';
  end if;
  update barn_members set role = new_role where barn_id = b and user_id = member;
end $$;

-- ---------- row level security ----------
alter table public.barns enable row level security;
alter table public.barn_members enable row level security;
alter table public.docs enable row level security;
alter table public.signups enable row level security;
alter table public.site_admins enable row level security;

drop policy if exists "members read barn" on public.barns;
create policy "members read barn" on public.barns for select using (public.is_member(id));
drop policy if exists "owners rename barn" on public.barns;
create policy "owners rename barn" on public.barns for update using (public.is_owner(id));

drop policy if exists "members read members" on public.barn_members;
create policy "members read members" on public.barn_members for select using (public.is_member(barn_id));
drop policy if exists "owners remove members" on public.barn_members;
create policy "owners remove members" on public.barn_members for delete using (public.is_owner(barn_id) or user_id = auth.uid());

drop policy if exists "members read docs" on public.docs;
create policy "members read docs" on public.docs for select using (public.is_member(barn_id));
drop policy if exists "anyone reads stallion listings" on public.docs;
create policy "anyone reads stallion listings" on public.docs for select using (coll = 'studs' and coalesce(data->>'unlisted', 'false') <> 'true');
drop policy if exists "writers insert docs" on public.docs;
create policy "writers insert docs" on public.docs for insert with check (public.can_write(barn_id));
drop policy if exists "writers update docs" on public.docs;
create policy "writers update docs" on public.docs for update using (public.can_write(barn_id)) with check (public.can_write(barn_id));
drop policy if exists "writers delete docs" on public.docs;
create policy "writers delete docs" on public.docs for delete using (public.can_write(barn_id));

drop policy if exists "anyone signs up" on public.signups;
create policy "anyone signs up" on public.signups for insert to anon, authenticated with check (true);
drop policy if exists "admins read signups" on public.signups;
create policy "admins read signups" on public.signups for select using (public.is_site_admin());

drop policy if exists "admins see admins" on public.site_admins;
create policy "admins see admins" on public.site_admins for select using (user_id = auth.uid());

-- ---------- realtime ----------
do $$ begin
  alter publication supabase_realtime add table public.docs;
exception when duplicate_object then null; end $$;

-- ---------- photo & video storage ----------
insert into storage.buckets (id, name, public, file_size_limit)
  values ('media', 'media', true, 20971520)
  on conflict (id) do update set public = true, file_size_limit = 20971520;

drop policy if exists "barn members upload media" on storage.objects;
create policy "barn members upload media" on storage.objects for insert to authenticated
  with check (bucket_id = 'media' and public.can_write(((storage.foldername(name))[1])::uuid));
drop policy if exists "barn members delete media" on storage.objects;
create policy "barn members delete media" on storage.objects for delete to authenticated
  using (bucket_id = 'media' and public.can_write(((storage.foldername(name))[1])::uuid));
