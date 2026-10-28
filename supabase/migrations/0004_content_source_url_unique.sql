-- Lets the sync-content Edge Function upsert by citation URL.
alter table public.content_items
  add constraint content_items_source_url_key unique (source_url);
