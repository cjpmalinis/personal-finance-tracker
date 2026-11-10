-- Personal Finance Manager schema
-- Run this whole file in Supabase SQL Editor.
-- Uses Supabase Auth user IDs and Row Level Security. Never expose service_role keys in the browser.

create extension if not exists pgcrypto;

create table if not exists public.income_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  entry_date date not null,
  period text not null default '1st half',
  source text not null,
  salary numeric(14,2) not null default 0 check (salary >= 0),
  pera numeric(14,2) not null default 0 check (pera >= 0),
  other_income numeric(14,2) not null default 0 check (other_income >= 0),
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.deduction_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  entry_date date not null,
  period text not null default '1st half',
  gsis numeric(14,2) not null default 0 check (gsis >= 0),
  pagibig numeric(14,2) not null default 0 check (pagibig >= 0),
  philhealth numeric(14,2) not null default 0 check (philhealth >= 0),
  g_flex numeric(14,2) not null default 0 check (g_flex >= 0),
  e_loan numeric(14,2) not null default 0 check (e_loan >= 0),
  other_deductions numeric(14,2) not null default 0 check (other_deductions >= 0),
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.debts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  creditor text not null,
  opening_balance numeric(14,2) not null default 0 check (opening_balance >= 0),
  new_charges numeric(14,2) not null default 0 check (new_charges >= 0),
  interest_fees numeric(14,2) not null default 0 check (interest_fees >= 0),
  due_date date,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  entry_date date not null,
  payee text not null,
  category text not null default 'Other',
  amount numeric(14,2) not null check (amount > 0),
  debt_id uuid references public.debts(id) on delete set null,
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists income_entries_user_date_idx on public.income_entries(user_id, entry_date);
create index if not exists deduction_entries_user_date_idx on public.deduction_entries(user_id, entry_date);
create index if not exists expenses_user_date_idx on public.expenses(user_id, entry_date);
create index if not exists expenses_debt_id_idx on public.expenses(debt_id);
create index if not exists debts_user_idx on public.debts(user_id);

alter table public.income_entries enable row level security;
alter table public.deduction_entries enable row level security;
alter table public.debts enable row level security;
alter table public.expenses enable row level security;

drop policy if exists "owner manages income" on public.income_entries;
create policy "owner manages income" on public.income_entries
for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "owner manages deductions" on public.deduction_entries;
create policy "owner manages deductions" on public.deduction_entries
for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "owner manages debts" on public.debts;
create policy "owner manages debts" on public.debts
for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "owner manages expenses" on public.expenses;
create policy "owner manages expenses" on public.expenses
for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Prevent users from linking an expense to another user's debt.
create or replace function public.validate_expense_debt_owner()
returns trigger language plpgsql security invoker set search_path = public
as $$
begin
  if new.debt_id is not null and not exists (
    select 1 from public.debts d where d.id = new.debt_id and d.user_id = auth.uid()
  ) then
    raise exception 'Selected loan does not belong to the signed-in user';
  end if;
  return new;
end;
$$;

drop trigger if exists expenses_debt_owner_check on public.expenses;
create trigger expenses_debt_owner_check
before insert or update of debt_id on public.expenses
for each row execute function public.validate_expense_debt_owner();

-- Optional: disable public sign-ups in Supabase Dashboard > Authentication > Settings.
-- Create your one account manually in Authentication > Users.
