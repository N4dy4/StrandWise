-- How-to videos per hairstyle (links out to the platform; nothing re-hosted, R2).
-- style_name matches HairstyleRecommender style names in the app.
create table if not exists public.hairstyle_tutorials (
  id uuid primary key default gen_random_uuid(),
  style_name text not null,
  title text not null,
  source_name text not null,
  source_url text not null unique check (source_url <> ''),
  thumbnail_url text not null default '',
  platform text not null default 'youtube' check (platform in ('youtube', 'tiktok')),
  curl_patterns text[] not null default '{}',
  created_at timestamptz not null default now()
);

create index if not exists hairstyle_tutorials_style_idx
  on public.hairstyle_tutorials (style_name);

alter table public.hairstyle_tutorials enable row level security;

drop policy if exists "read hairstyle tutorials" on public.hairstyle_tutorials;
create policy "read hairstyle tutorials" on public.hairstyle_tutorials
  for select to anon, authenticated using (true);
