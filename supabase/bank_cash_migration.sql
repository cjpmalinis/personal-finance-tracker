-- Personal Finance Manager: Bank & Cash module migration
-- Run once in Supabase SQL Editor AFTER the original schema.sql.
-- Existing salary, deduction, debt and expense records are preserved.

create table if not exists public.accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  account_type text not null default 'Bank'
    check (account_type in ('Bank','E-wallet','Cash on hand','Other')),
  opening_balance numeric(14,2) not null default 0 check (opening_balance >= 0),
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.account_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  account_id uuid not null references public.accounts(id) on delete restrict,
  transaction_date date not null,
  transaction_type text not null check (transaction_type in ('Deposit','Withdrawal')),
  amount numeric(14,2) not null check (amount > 0),
  description text not null,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.account_transfers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  from_account_id uuid not null references public.accounts(id) on delete restrict,
  to_account_id uuid not null references public.accounts(id) on delete restrict,
  transfer_date date not null,
  amount numeric(14,2) not null check (amount > 0),
  notes text,
  created_at timestamptz not null default now(),
  constraint different_transfer_accounts check (from_account_id <> to_account_id)
);

create index if not exists accounts_user_name_idx on public.accounts(user_id, name);
create index if not exists account_transactions_user_date_idx on public.account_transactions(user_id, transaction_date);
create index if not exists account_transactions_account_idx on public.account_transactions(account_id);
create index if not exists account_transfers_user_date_idx on public.account_transfers(user_id, transfer_date);
create index if not exists account_transfers_from_idx on public.account_transfers(from_account_id);
create index if not exists account_transfers_to_idx on public.account_transfers(to_account_id);

alter table public.accounts enable row level security;
alter table public.account_transactions enable row level security;
alter table public.account_transfers enable row level security;

drop policy if exists "owner manages accounts" on public.accounts;
create policy "owner manages accounts" on public.accounts
for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "owner manages account transactions" on public.account_transactions;
create policy "owner manages account transactions" on public.account_transactions
for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "owner manages account transfers" on public.account_transfers;
create policy "owner manages account transfers" on public.account_transfers
for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Ensure a transaction can only use an account owned by the signed-in user.
create or replace function public.validate_account_transaction_owner()
returns trigger language plpgsql security invoker set search_path = public
as $$
begin
  if not exists (
    select 1 from public.accounts a
    where a.id = new.account_id and a.user_id = auth.uid()
  ) then
    raise exception 'Selected account does not belong to the signed-in user';
  end if;
  return new;
end;
$$;

drop trigger if exists account_transaction_owner_check on public.account_transactions;
create trigger account_transaction_owner_check
before insert or update of account_id on public.account_transactions
for each row execute function public.validate_account_transaction_owner();

-- Ensure both sides of a transfer belong to the signed-in user.
create or replace function public.validate_account_transfer_owner()
returns trigger language plpgsql security invoker set search_path = public
as $$
begin
  if new.from_account_id = new.to_account_id then
    raise exception 'Choose two different accounts';
  end if;
  if not exists (
    select 1 from public.accounts a
    where a.id = new.from_account_id and a.user_id = auth.uid()
  ) or not exists (
    select 1 from public.accounts a
    where a.id = new.to_account_id and a.user_id = auth.uid()
  ) then
    raise exception 'Both transfer accounts must belong to the signed-in user';
  end if;
  return new;
end;
$$;

drop trigger if exists account_transfer_owner_check on public.account_transfers;
create trigger account_transfer_owner_check
before insert or update of from_account_id, to_account_id on public.account_transfers
for each row execute function public.validate_account_transfer_owner();
