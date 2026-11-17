-- Video platform + thumbnail so the feed can show YouTube and TikTok items.
-- thumbnail_url is a hotlink to the platform's own image (nothing re-hosted).
alter table public.content_items
  add column if not exists platform text not null default 'web'
    check (platform in ('youtube', 'tiktok', 'web')),
  add column if not exists thumbnail_url text not null default '',
  add column if not exists published_at timestamptz;

update public.content_items set platform = 'youtube'
  where source_url like '%youtube.com/%' or source_url like '%youtu.be/%';
