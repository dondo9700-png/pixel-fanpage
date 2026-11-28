-- 픽셀 팬카페 게시판 테이블. Supabase 대시보드의 SQL Editor에서 한 번 실행하면 됩니다.
-- 여러 번 실행해도 안전합니다(있으면 건너뜀).
--
-- · cafe_posts   글 (누구나 읽기, 올리기는 아래 함수로만)
-- · cafe_comments 댓글 (누구나 읽기·쓰기)
-- · cafe_post_keys 삭제용 4자리 비밀번호의 md5 해시. 정책을 만들지 않아 anon은 읽을 수 없습니다.
-- · 로그인 없이 쓰는 게시판이라 4자리 비밀번호는 '남의 글을 실수로 지우지 않게 하는 잠금'입니다.
--   중요한 개인정보나 비밀번호를 글에 적지 마세요.

create table if not exists public.cafe_posts (
  id bigint generated always as identity primary key,
  board text not null default 'free' check (board in ('notice','free','fanart','clip')),
  streamer text not null default '' check (char_length(streamer) <= 20),
  title text not null check (char_length(title) between 1 and 80),
  body text not null default '' check (char_length(body) <= 4000),
  image_url text not null default '' check (char_length(image_url) <= 500),
  author text not null default '익명' check (char_length(author) between 1 and 12),
  likes integer not null default 0 check (likes between 0 and 1000000),
  created_at timestamptz not null default now()
);

create table if not exists public.cafe_comments (
  id bigint generated always as identity primary key,
  post_id bigint not null references public.cafe_posts(id) on delete cascade,
  author text not null default '익명' check (char_length(author) between 1 and 12),
  body text not null check (char_length(body) between 1 and 500),
  created_at timestamptz not null default now()
);

create table if not exists public.cafe_post_keys (
  post_id bigint primary key references public.cafe_posts(id) on delete cascade,
  pin_hash text not null
);

create index if not exists cafe_posts_created_idx on public.cafe_posts (created_at desc);
create index if not exists cafe_comments_post_idx on public.cafe_comments (post_id, created_at);

alter table public.cafe_posts enable row level security;
alter table public.cafe_comments enable row level security;
alter table public.cafe_post_keys enable row level security;

-- 글과 댓글은 누구나 읽는다.
drop policy if exists "cafe posts are public" on public.cafe_posts;
create policy "cafe posts are public" on public.cafe_posts
  for select to anon, authenticated using (true);

drop policy if exists "cafe comments are public" on public.cafe_comments;
create policy "cafe comments are public" on public.cafe_comments
  for select to anon, authenticated using (true);

drop policy if exists "anyone can comment" on public.cafe_comments;
create policy "anyone can comment" on public.cafe_comments
  for insert to anon, authenticated with check (true);

-- cafe_posts 의 insert 정책은 만들지 않는다 → 글쓰기는 아래 cafe_create_post 함수로만.
-- cafe_post_keys 에는 정책을 만들지 않는다 → anon은 해시를 읽거나 쓸 수 없다.

-- 글쓰기: 글과 비밀번호 해시를 한 번에 넣고 새 글 id를 돌려준다.
create or replace function public.cafe_create_post(
  p_board text, p_streamer text, p_title text, p_body text,
  p_image text, p_author text, p_pin text
) returns bigint
language plpgsql security definer set search_path = public as $$
declare v_id bigint;
begin
  if coalesce(p_pin,'') !~ '^[0-9]{4}$' then
    raise exception '삭제용 비밀번호는 숫자 4자리여야 합니다.';
  end if;
  insert into public.cafe_posts (board, streamer, title, body, image_url, author)
  values (
    case when p_board in ('notice','free','fanart','clip') then p_board else 'free' end,
    left(coalesce(p_streamer,''),20),
    left(coalesce(p_title,''),80),
    left(coalesce(p_body,''),4000),
    left(coalesce(p_image,''),500),
    left(coalesce(nullif(btrim(p_author),''),'익명'),12)
  )
  returning id into v_id;

  insert into public.cafe_post_keys (post_id, pin_hash) values (v_id, md5(p_pin));
  return v_id;
end $$;

-- 글 지우기: 적어 둔 4자리 비밀번호가 맞을 때만 지운다.
create or replace function public.cafe_delete_post(p_id bigint, p_pin text)
returns boolean
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  delete from public.cafe_posts cp
   where cp.id = p_id
     and exists (
       select 1 from public.cafe_post_keys k
        where k.post_id = cp.id and k.pin_hash = md5(coalesce(p_pin,''))
     );
  get diagnostics n = row_count;
  return n > 0;
end $$;

-- 좋아요: 로그인 없이 숫자만 올리고 내린다.
create or replace function public.cafe_like(p_id bigint, p_delta int)
returns int
language plpgsql security definer set search_path = public as $$
declare v int;
begin
  update public.cafe_posts
     set likes = greatest(0, likes + case when coalesce(p_delta,1) < 0 then -1 else 1 end)
   where id = p_id
   returning likes into v;
  return coalesce(v,0);
end $$;

grant execute on function public.cafe_create_post(text,text,text,text,text,text,text) to anon, authenticated;
grant execute on function public.cafe_delete_post(bigint,text) to anon, authenticated;
grant execute on function public.cafe_like(bigint,int) to anon, authenticated;
