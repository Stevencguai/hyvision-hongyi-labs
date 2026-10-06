-- HYVISION-HONGYI LABS: run this script in Supabase SQL Editor.
create table if not exists public.site_content (
  id bigint primary key generated always as identity,
  studio_name text not null default 'HYVISION-HONGYI LABS',
  eyebrow text not null default 'PORTRAIT STUDIO / NEW TAIPEI',
  hero_title text not null default '留下你最真實的樣子。',
  hero_image text not null default '/images/portrait-main.jpg',
  intro_title text not null default '關於工作室',
  intro text not null default '',
  photographer text not null default '張鴻毅',
  address text not null default '',
  phone text not null default '',
  email text not null default '',
  line_id text not null default '',
  line_url text not null default '',
  instagram text not null default '',
  updated_at timestamptz not null default now()
);

create table if not exists public.photos (
  id bigint primary key generated always as identity,
  title text not null,
  category text not null check (category in ('人像 Portrait', '形象照 Branding')),
  url text not null,
  storage_path text,
  created_at timestamptz not null default now()
);

alter table public.site_content enable row level security;
alter table public.photos enable row level security;

drop policy if exists "Public can read site content" on public.site_content;
create policy "Public can read site content" on public.site_content for select using (true);
drop policy if exists "Authenticated users can manage site content" on public.site_content;
create policy "Authenticated users can manage site content" on public.site_content for all to authenticated using (true) with check (true);

drop policy if exists "Public can read photos" on public.photos;
create policy "Public can read photos" on public.photos for select using (true);
drop policy if exists "Authenticated users can manage photos" on public.photos;
create policy "Authenticated users can manage photos" on public.photos for all to authenticated using (true) with check (true);

insert into public.site_content (studio_name, eyebrow, hero_title, hero_image, intro_title, intro, photographer, address, phone, email, line_id, line_url, instagram)
select 'HYVISION-HONGYI LABS', 'PORTRAIT STUDIO / NEW TAIPEI', '留下你最真實的樣子。', '/images/portrait-main.jpg', '關於工作室', '我相信，好的肖像不是把人變成某個樣子，而是讓你在鏡頭前，安心地成為自己。從企劃、討論到拍攝，為每一位來到 HONGYI LABS 的人，留下自然、有質感的影像。', '張鴻毅', '新北市林口區忠孝路566號', '0905927367', 'stevencguai007@gmail.com', 'LINE 官方帳號', 'https://line.me/ti/p/dJVHfHRu5T', 'https://www.instagram.com/ye__picture/?utm_source=qr'
where not exists (select 1 from public.site_content);

-- The portfolio bucket is public so visitor browsers can load published images.
insert into storage.buckets (id, name, public)
values ('portfolio', 'portfolio', true)
on conflict (id) do update set public = true;

drop policy if exists "Public can view portfolio images" on storage.objects;
create policy "Public can view portfolio images" on storage.objects for select using (bucket_id = 'portfolio');
drop policy if exists "Authenticated users can upload portfolio images" on storage.objects;
create policy "Authenticated users can upload portfolio images" on storage.objects for insert to authenticated with check (bucket_id = 'portfolio');
drop policy if exists "Authenticated users can update portfolio images" on storage.objects;
create policy "Authenticated users can update portfolio images" on storage.objects for update to authenticated using (bucket_id = 'portfolio') with check (bucket_id = 'portfolio');
drop policy if exists "Authenticated users can delete portfolio images" on storage.objects;
create policy "Authenticated users can delete portfolio images" on storage.objects for delete to authenticated using (bucket_id = 'portfolio');
