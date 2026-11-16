-- Short product description shown on the products page, taken from the brand's page.
alter table public.products
  add column if not exists description text not null default '';
