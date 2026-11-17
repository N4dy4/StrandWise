-- sync-content upserts on source_url, so it must be unique (R2 permanent citation).
delete from public.content_items a
using public.content_items b
where a.source_url = b.source_url and a.ctid > b.ctid;

create unique index if not exists content_items_source_url_key
  on public.content_items (source_url);
