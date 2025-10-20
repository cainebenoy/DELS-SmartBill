-- DELS SmartBill - Supabase schema, policies, triggers, and optional RPCs
-- Safe to run on a fresh project. Review before applying to production.

-- Extensions
create extension if not exists pgcrypto; -- for gen_random_uuid

-- 1. Shared product catalog for the company
create table if not exists products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text,
  price numeric(10,2) not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

-- 2. Shared customer list for the company
create table if not exists customers (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

-- 3. All invoices from all employees
create table if not exists invoices (
  id uuid primary key default gen_random_uuid(),
  invoice_number text unique not null,
  customer_id uuid references customers(id),
  total_amount numeric(10,2) not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  created_by_user_id uuid references auth.users(id)
);

-- 4. Line items for each invoice
create table if not exists invoice_items (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid references invoices(id) on delete cascade,
  product_id uuid references products(id),
  quantity int not null,
  unit_price numeric(10,2) not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

-- Indices (helpful for queries)
create index if not exists idx_products_name on products (name);
create index if not exists idx_products_category on products (category);
create index if not exists idx_products_updated_at on products (updated_at);

create index if not exists idx_customers_name on customers (name);
create index if not exists idx_customers_updated_at on customers (updated_at);

create index if not exists idx_invoices_number on invoices (invoice_number);
create index if not exists idx_invoices_created_at on invoices (created_at);
create index if not exists idx_invoices_updated_at on invoices (updated_at);
create index if not exists idx_invoices_created_by on invoices (created_by_user_id);

create index if not exists idx_invoice_items_invoice_id on invoice_items (invoice_id);
create index if not exists idx_invoice_items_updated_at on invoice_items (updated_at);

-- RLS
alter table products enable row level security;
alter table customers enable row level security;
alter table invoices enable row level security;
alter table invoice_items enable row level security;

-- Authenticated users get full access
create policy "Allow all authenticated users" on products for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "Allow all authenticated users" on customers for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "Allow all authenticated users" on invoices for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "Allow all authenticated users" on invoice_items for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- Timestamp trigger function
create or replace function set_timestamp()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Attach triggers
create trigger set_timestamp_products
before update on products
for each row execute procedure set_timestamp();

create trigger set_timestamp_customers
before update on customers
for each row execute procedure set_timestamp();

create trigger set_timestamp_invoices
before update on invoices
for each row execute procedure set_timestamp();

create trigger set_timestamp_invoice_items
before update on invoice_items
for each row execute procedure set_timestamp();

-- Soft delete helpers (optional): views could filter deleted_at is null on client side

-- Invoice numbering sequence and assignment
create sequence if not exists invoice_seq start 1 increment 1;

create or replace function assign_invoice_number()
returns trigger as $$
declare
  next_no bigint;
  formatted text;
begin
  if (new.invoice_number is null or new.invoice_number like 'LOCAL-%') then
    select nextval('invoice_seq') into next_no;
    formatted := 'DELS-' || lpad(next_no::text, 6, '0');
    new.invoice_number := formatted;
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trg_assign_invoice_number
before insert on invoices
for each row execute procedure assign_invoice_number();

-- Optional RPCs for sync: fetch changes since timestamp (exclude soft-deleted if desired)
create or replace function fetch_products_since(since timestamptz)
returns setof products as $$
  select * from products where updated_at > since or (deleted_at is not null and deleted_at > since);
$$ language sql stable;

create or replace function fetch_customers_since(since timestamptz)
returns setof customers as $$
  select * from customers where updated_at > since or (deleted_at is not null and deleted_at > since);
$$ language sql stable;

create or replace function fetch_invoices_since(since timestamptz)
returns setof invoices as $$
  select * from invoices where updated_at > since or (deleted_at is not null and deleted_at > since);
$$ language sql stable;

create or replace function fetch_invoice_items_since(since timestamptz)
returns setof invoice_items as $$
  select * from invoice_items where updated_at > since or (deleted_at is not null and deleted_at > since);
$$ language sql stable;
