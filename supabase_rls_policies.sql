-- Run this in Supabase SQL Editor after the tables in supabase_schema.sql exist.
-- It enables row-level security and adds role-aware policies for app data.

create or replace function public.current_user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.users where id = auth.uid()
$$;

create or replace function public.is_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_user_role() in ('admin', 'manager', 'loan_manager', 'loan_officer'), false)
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_user_role() = 'admin', false)
$$;

alter table public.users enable row level security;
alter table public.profiles enable row level security;
alter table public.borrowers enable row level security;
alter table public.loan_applications enable row level security;
alter table public.documents enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;
alter table public.push_device_tokens enable row level security;
alter table public.audit_logs enable row level security;
alter table public.loan_products enable row level security;
alter table public.notification_templates enable row level security;
alter table public.reports enable row level security;

drop policy if exists "users can read own row" on public.users;
create policy "users can read own row" on public.users
for select using (id = auth.uid() or public.is_staff());

drop policy if exists "admins manage users" on public.users;
create policy "admins manage users" on public.users
for all using (public.is_admin()) with check (public.is_admin());

drop policy if exists "profiles own read update" on public.profiles;
create policy "profiles own read update" on public.profiles
for all using (id = auth.uid() or public.is_staff()) with check (id = auth.uid() or public.is_staff());

drop policy if exists "borrowers own or staff" on public.borrowers;
create policy "borrowers own or staff" on public.borrowers
for all using (user_id = auth.uid() or public.is_staff()) with check (user_id = auth.uid() or public.is_staff());

drop policy if exists "applications borrower or staff" on public.loan_applications;
create policy "applications borrower or staff" on public.loan_applications
for all using (
  public.is_staff()
  or exists (
    select 1 from public.borrowers b
    where b.borrower_id = loan_applications.borrower_id
      and b.user_id = auth.uid()
  )
) with check (
  public.is_staff()
  or exists (
    select 1 from public.borrowers b
    where b.borrower_id = loan_applications.borrower_id
      and b.user_id = auth.uid()
  )
);

drop policy if exists "documents borrower or staff" on public.documents;
create policy "documents borrower or staff" on public.documents
for all using (
  public.is_staff()
  or exists (
    select 1 from public.borrowers b
    where b.borrower_id = documents.borrower_id
      and b.user_id = auth.uid()
  )
) with check (
  public.is_staff()
  or exists (
    select 1 from public.borrowers b
    where b.borrower_id = documents.borrower_id
      and b.user_id = auth.uid()
  )
);

drop policy if exists "messages participants or staff" on public.messages;
create policy "messages participants or staff" on public.messages
for all using (sender_id = auth.uid() or receiver_id = auth.uid() or public.is_staff())
with check (sender_id = auth.uid() or public.is_staff());

drop policy if exists "notifications own or staff" on public.notifications;
create policy "notifications own or staff" on public.notifications
for all using (user_id = auth.uid() or public.is_staff()) with check (user_id = auth.uid() or public.is_staff());

drop policy if exists "push tokens own device rows" on public.push_device_tokens;
create policy "push tokens own device rows" on public.push_device_tokens
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "staff read products" on public.loan_products;
create policy "staff read products" on public.loan_products
for select using (is_active = true or public.is_staff());

drop policy if exists "admins manage products" on public.loan_products;
create policy "admins manage products" on public.loan_products
for all using (public.is_admin()) with check (public.is_admin());

drop policy if exists "staff audit read" on public.audit_logs;
create policy "staff audit read" on public.audit_logs
for select using (public.is_staff());

drop policy if exists "staff reports" on public.reports;
create policy "staff reports" on public.reports
for all using (generated_by = auth.uid() or public.is_staff()) with check (generated_by = auth.uid() or public.is_staff());
