-- Product recommendations need the same hair-type targeting as content items.
alter table public.products
  add column if not exists curl_patterns text[] not null default '{}';
