-- Plain-language ingredient explainers, each with a cited source (R2).
alter table public.ingredients
  add column if not exists what_it_is text not null default '',
  add column if not exists why_used text not null default '',
  add column if not exists hair_effects text not null default '',
  add column if not exists info_source_url text not null default '';
