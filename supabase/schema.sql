-- MEMBER HUB — run this entire script in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  role text not null default 'user' check (role in ('user','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.member_registrations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  full_name text not null check (char_length(trim(full_name)) between 2 and 120),
  member_code text not null unique check (char_length(trim(member_code)) between 1 and 40),
  created_at timestamptz not null default now()
);

create index if not exists member_registrations_user_id_idx on public.member_registrations(user_id);
create index if not exists member_registrations_created_at_idx on public.member_registrations(created_at desc);

create or replace function public.is_admin()
returns boolean language sql stable security definer
set search_path = public
as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name',''));
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.member_registrations enable row level security;

drop policy if exists "Users can view own profile and admins all" on public.profiles;
create policy "Users can view own profile and admins all" on public.profiles
for select to authenticated using (id = auth.uid() or public.is_admin());

drop policy if exists "Users can update own display name" on public.profiles;
create policy "Users can update own display name" on public.profiles
for update to authenticated using (id = auth.uid()) with check (id = auth.uid() and role = (select p.role from public.profiles p where p.id = auth.uid()));

drop policy if exists "Users view own registrations and admins all" on public.member_registrations;
create policy "Users view own registrations and admins all" on public.member_registrations
for select to authenticated using (user_id = auth.uid() or public.is_admin());

drop policy if exists "Users create own registrations" on public.member_registrations;
create policy "Users create own registrations" on public.member_registrations
for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "Admins delete registrations" on public.member_registrations;
create policy "Admins delete registrations" on public.member_registrations
for delete to authenticated using (public.is_admin());

grant usage on schema public to authenticated;
grant select, update on public.profiles to authenticated;
grant select, insert, delete on public.member_registrations to authenticated;

-- After registering your own account, promote it to admin manually:
-- update public.profiles
-- set role = 'admin'
-- where id = (select id from auth.users where email = 'YOUR_EMAIL@example.com');
-- Never expose a service_role key in frontend code.
