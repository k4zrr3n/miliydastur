-- Milliy Dastur: boshlang'ich Supabase schema.
-- Run in Supabase SQL Editor. Test in a separate project before production.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  role text not null default 'student' check (role in ('student','curator','admin')),
  is_enabled boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.learning_materials (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  category text not null default 'Umumiy',
  storage_path text,
  file_name text,
  mime_type text,
  is_published boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.academic_clubs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null default '',
  is_open boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.diagnostic_attempts (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references auth.users(id) on delete cascade,
  test_code text not null,
  score integer not null default 0,
  total integer not null default 0,
  answers jsonb not null default '{}'::jsonb,
  completed_at timestamptz not null default now()
);

create table if not exists public.platform_settings (
  setting_key text primary key,
  setting_value jsonb not null default '{}'::jsonb,
  updated_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default now()
);

create or replace function public.jwt_role()
returns text language sql stable as $$
  select coalesce(auth.jwt()->'app_metadata'->>'role', 'student');
$$;

create or replace function public.is_staff()
returns boolean language sql stable as $$
  select public.jwt_role() in ('admin','curator');
$$;

alter table public.profiles enable row level security;
alter table public.learning_materials enable row level security;
alter table public.academic_clubs enable row level security;
alter table public.diagnostic_attempts enable row level security;
alter table public.platform_settings enable row level security;

drop policy if exists "profile self or staff read" on public.profiles;
create policy "profile self or staff read" on public.profiles
for select to authenticated using (id = auth.uid() or public.is_staff());
drop policy if exists "staff manage profiles" on public.profiles;
create policy "staff manage profiles" on public.profiles
for all to authenticated using (public.jwt_role() = 'admin')
with check (public.jwt_role() = 'admin');

drop policy if exists "read published learning materials" on public.learning_materials;
create policy "read published learning materials" on public.learning_materials
for select to authenticated using (is_published or public.is_staff());
drop policy if exists "staff manage learning materials" on public.learning_materials;
create policy "staff manage learning materials" on public.learning_materials
for all to authenticated using (public.is_staff()) with check (public.is_staff());

drop policy if exists "read open clubs" on public.academic_clubs;
create policy "read open clubs" on public.academic_clubs
for select to authenticated using (is_open or public.is_staff());
drop policy if exists "staff manage clubs" on public.academic_clubs;
create policy "staff manage clubs" on public.academic_clubs
for all to authenticated using (public.is_staff()) with check (public.is_staff());

drop policy if exists "students read own diagnostic attempts" on public.diagnostic_attempts;
create policy "students read own diagnostic attempts" on public.diagnostic_attempts
for select to authenticated using (student_id = auth.uid() or public.is_staff());
drop policy if exists "students insert own diagnostic attempts" on public.diagnostic_attempts;
create policy "students insert own diagnostic attempts" on public.diagnostic_attempts
for insert to authenticated with check (student_id = auth.uid());
drop policy if exists "staff manage diagnostic attempts" on public.diagnostic_attempts;
create policy "staff manage diagnostic attempts" on public.diagnostic_attempts
for all to authenticated using (public.is_staff()) with check (public.is_staff());

drop policy if exists "staff manage platform settings" on public.platform_settings;
create policy "staff manage platform settings" on public.platform_settings
for all to authenticated using (public.is_staff()) with check (public.is_staff());

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('learning-materials','learning-materials',false,52428800,
  array['application/pdf','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.ms-powerpoint','application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'application/vnd.ms-excel','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'text/plain','image/jpeg','image/png'])
on conflict (id) do nothing;

drop policy if exists "signed-in read learning files" on storage.objects;
create policy "signed-in read learning files" on storage.objects
for select to authenticated using (bucket_id = 'learning-materials');
drop policy if exists "staff upload learning files" on storage.objects;
create policy "staff upload learning files" on storage.objects
for insert to authenticated with check (bucket_id = 'learning-materials' and public.is_staff());
drop policy if exists "staff update learning files" on storage.objects;
create policy "staff update learning files" on storage.objects
for update to authenticated using (bucket_id = 'learning-materials' and public.is_staff())
with check (bucket_id = 'learning-materials' and public.is_staff());
drop policy if exists "staff delete learning files" on storage.objects;
create policy "staff delete learning files" on storage.objects
for delete to authenticated using (bucket_id = 'learning-materials' and public.is_staff());
