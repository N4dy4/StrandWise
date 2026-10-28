-- Phase 2: content feed + product knowledge base. RLS on everything (R4).
-- Content/product catalogs are read-only to signed-in users; writes via service role only.

create table if not exists public.content_items (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('video', 'article')),
  title text not null,
  source_name text not null,
  source_url text not null check (source_url <> ''), -- R2: permanent citation
  curl_patterns text[] not null default '{}',
  concerns text[] not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.ingredients (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  flag text check (flag in ('sulfate', 'silicone', 'dryingAlcohol'))
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  brand text not null,
  source_url text not null check (source_url <> '')
);

create table if not exists public.product_ingredients (
  product_id uuid not null references public.products on delete cascade,
  ingredient_id uuid not null references public.ingredients,
  position int not null,
  primary key (product_id, ingredient_id)
);

alter table public.content_items enable row level security;
alter table public.ingredients enable row level security;
alter table public.products enable row level security;
alter table public.product_ingredients enable row level security;

create policy "read content" on public.content_items for select to authenticated using (true);
create policy "read ingredients" on public.ingredients for select to authenticated using (true);
create policy "read products" on public.products for select to authenticated using (true);
create policy "read product_ingredients" on public.product_ingredients for select to authenticated using (true);
