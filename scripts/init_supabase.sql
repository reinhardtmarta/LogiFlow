-- SQL to initialize Supabase tables for LogiFlow
create extension if not exists "pgcrypto";

-- profiles table
create table if not exists profiles (
  id uuid primary key default auth.uid(),
  user_id uuid references auth.users(id) on delete cascade,
  name text,
  address text,
  accepted_terms boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- products table
create table if not exists products (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid references auth.users(id) on delete cascade,
  name text not null,
  description text,
  price numeric(10,2),
  unit text,
  category text,
  is_rescue boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- inventory
create table if not exists inventory (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references products(id) on delete cascade,
  quantity integer not null default 0,
  location text,
  expiry_date date,
  address text,
  updated_at timestamptz default now()
);

-- feed posts
create table if not exists feed_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid references auth.users(id) on delete cascade,
  title text,
  body text,
  metadata jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- messages
create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid references auth.users(id) on delete cascade,
  receiver_id uuid references auth.users(id) on delete cascade,
  message text not null,
  created_at timestamptz default now()
);

-- Indexes
create index if not exists idx_products_seller on products(seller_id);
create index if not exists idx_inventory_product on inventory(product_id);
create index if not exists idx_feed_author on feed_posts(author_id);
create index if not exists idx_messages_pair on messages(sender_id, receiver_id);
