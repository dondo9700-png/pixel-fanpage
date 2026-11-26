-- 응원 게시판 테이블. Supabase 대시보드의 SQL Editor에서 한 번 실행합니다.
create table public.cheers (
  id bigint generated always as identity primary key,
  g text not null check (char_length(g) = 640 and g !~ '[^0-5.]'),          -- 32x20 도트 그림 (칸마다 색 번호 또는 빈칸)
  n text not null default '' check (char_length(n) <= 12), -- 닉네임
  created_at timestamptz not null default now()
);

alter table public.cheers enable row level security;

-- 누구나 읽고 올릴 수 있음. 수정과 삭제는 대시보드(관리자)에서만 가능.
create policy "anyone can read"  on public.cheers for select to anon using (true);
create policy "anyone can post"  on public.cheers for insert to anon with check (true);
