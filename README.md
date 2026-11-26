# 픽셀네트워크 팬페이지

팬이 만든 비공식 팬페이지입니다. 픽셀네트워크 및 소속 크리에이터와 관련이 없습니다.

- `index.html` 페이지 전체 (빌드 과정 없음)
- `img/` 크리에이터 치지직 프로필 이미지 (권리는 각 크리에이터에게 있음)
- `supabase.sql` 응원 게시판 테이블과 권한

## 응원 게시판 켜기

1. Supabase에서 프로젝트를 만들고 SQL Editor에서 `supabase.sql`을 실행합니다.
2. `index.html`의 `SUPA_URL`, `SUPA_KEY`에 프로젝트 URL과 공개(anon/publishable) 키를 넣습니다.
   `service_role` 같은 비밀 키는 절대 넣지 않습니다.
3. 부적절한 그림은 Supabase 대시보드의 Table Editor에서 해당 행을 지웁니다.
