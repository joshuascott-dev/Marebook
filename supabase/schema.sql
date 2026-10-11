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
create or replace function public.member_role(b uuid) returns text
language sql stable security definer set search_path = public as $$
  select role from barn_members where barn_id = b and user_id = auth.uid();
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

-- Join a barn with its 6-character code. Vets and trainers can join as themselves; owners can change roles later.
drop function if exists public.join_barn(text);
create or replace function public.join_barn(code text, as_role text default 'Staff') returns uuid
language plpgsql security definer set search_path = public as $$
declare b uuid; u auth.users%rowtype; r text := case when as_role in ('Staff','Vet','Trainer') then as_role else 'Staff' end;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  select id into b from barns where join_code = upper(trim(code));
  if b is null then raise exception 'No barn with that code'; end if;
  select * into u from auth.users where id = auth.uid();
  insert into barn_members(barn_id, user_id, role, display_name, email)
    values (b, auth.uid(), r, coalesce(u.raw_user_meta_data->>'contact', split_part(u.email, '@', 1)), u.email)
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
-- Vets see the barn's records but not its money.
create policy "members read docs" on public.docs for select using (public.is_member(barn_id) and not (coll in ('expenses','recurring') and public.member_role(barn_id) = 'Vet'));
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

-- ---------- audit trail ----------
-- Every insert, change and delete on docs is recorded by the database: who, when, and which fields changed.
-- Nobody can write or edit these rows from the app; members of the barn can read them.
create table if not exists public.docs_audit (
  id bigint generated always as identity primary key,
  barn_id uuid not null references public.barns(id) on delete cascade,
  coll text not null,
  doc_id text not null,
  mare_id text,
  action text not null check (action in ('insert','update','delete')),
  label text,
  changes jsonb,
  changed_by uuid default auth.uid(),
  at timestamptz not null default now()
);
create index if not exists docs_audit_barn_at on public.docs_audit(barn_id, at desc);
create index if not exists docs_audit_mare on public.docs_audit(barn_id, mare_id, at desc);
alter table public.docs_audit enable row level security;
drop policy if exists "members read audit" on public.docs_audit;
create policy "members read audit" on public.docs_audit for select using (public.is_member(barn_id) and not (coll in ('expenses','recurring') and public.member_role(barn_id) = 'Vet'));

create or replace function public.audit_docs() returns trigger
language plpgsql security definer set search_path = public as $$
declare ch jsonb := '{}'::jsonb; k text; src jsonb := coalesce(new.data, old.data);
begin
  if tg_op = 'UPDATE' then
    for k in select jsonb_object_keys(coalesce(old.data, '{}'::jsonb) || coalesce(new.data, '{}'::jsonb)) loop
      if (old.data -> k) is distinct from (new.data -> k) and k not in ('updatedAt') then
        ch := ch || jsonb_build_object(k, jsonb_build_array(old.data -> k, new.data -> k));
      end if;
    end loop;
    if ch = '{}'::jsonb then return new; end if;
  end if;
  if coalesce(new.coll, old.coll) = 'settings' then return coalesce(new, old); end if;
  insert into docs_audit(barn_id, coll, doc_id, mare_id, action, label, changes, changed_by)
  values (coalesce(new.barn_id, old.barn_id), coalesce(new.coll, old.coll), coalesce(new.id, old.id),
    case when coalesce(new.coll, old.coll) = 'mares' then coalesce(new.id, old.id) else src ->> 'mareId' end,
    lower(tg_op), coalesce(src ->> 'name', src ->> 'title'),
    case when tg_op = 'UPDATE' then ch else null end, auth.uid());
  return coalesce(new, old);
end $$;
drop trigger if exists docs_audit_trg on public.docs;
create trigger docs_audit_trg after insert or update or delete on public.docs for each row execute function public.audit_docs();

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
