# 픽셀네트워크 팬페이지

팬이 만든 비공식 팬페이지입니다. 픽셀네트워크 및 소속 크리에이터와 관련이 없습니다.

- `index.html` 페이지 전체 (빌드 과정 없음)
- `img/` 크리에이터 치지직 프로필 이미지 (권리는 각 크리에이터에게 있음)
- `supabase.sql` 응원 도트 게시판 테이블과 권한
- `supabase_cafe_schema.sql` 팬카페 게시판(글·댓글) 테이블과 함수

## 응원 도트 게시판 켜기

1. Supabase에서 프로젝트를 만들고 SQL Editor에서 `supabase.sql`을 실행합니다.
2. `index.html`의 `SUPA_URL`, `SUPA_KEY`에 프로젝트 URL과 공개(anon/publishable) 키를 넣습니다.
   `service_role` 같은 비밀 키는 절대 넣지 않습니다.
3. 부적절한 그림은 Supabase 대시보드의 Table Editor에서 해당 행을 지웁니다.

## 홈 화면 히어로

홈은 크리에이터 한 명씩 배경에 희미하게 지나가고, 아래 Streamer Spotlight에서
아바타를 눌러 다른 크리에이터로 바꿀 수 있습니다.

- 페이지를 열 때마다 26명 순서를 섞어서 다른 크리에이터부터 나옵니다. 한 바퀴 돌면 다시 섞습니다.
- 크리에이터마다 공식 유튜브 쇼츠·영상 ID를 `V` 객체에 넣어 두었고, 나올 때마다 그중 하나를
  무작위로 골라 무음 자동재생(투명도 0.32, 화면을 꽉 채우는 크롭, 클릭은 통과)으로 깔아 줍니다.
  ID는 모두 `youtube.com/oembed`로 실제 존재·임베드 가능 여부를 확인한 것입니다.
- 영상이 없는 크리에이터는 프로필 사진 평균색 배경 + 초상 모션으로 나옵니다.
- 무음 루프 MP4를 쓰고 싶으면 `index.html`의 `R` 배열에서 해당 크리에이터 행 끝(`r[7]`)에 주소를 넣으면 됩니다.

## 방송 중(LIVE) 표시

`index.html`의 `LIVE_ENDPOINT`(기본값 `.../functions/v1/chzzk-live`)가 치지직 라이브 상태를
한 번에 돌려주면 이름 옆에 빨간 점과 `LIVE` 뱃지가 붙습니다(홈 스포트라이트, CREATORS 카드,
카페 스트리머 필터·글 태그). 3분마다 다시 확인합니다.

응답 형식은 아래 중 하나면 됩니다.

```json
{ "live": ["<치지직 채널 ID>", "..."] }
```

`{ "ids": [...] }`, `{ "channels": [...] }`, 문자열 배열, `{ "live": { "<id>": true } }` 도 받습니다.
프록시가 아직 배포되지 않았거나(404) 네트워크가 막혀 있으면 아무 표시 없이 조용히 넘어갑니다.

## 팬카페 게시판(글·댓글) 켜기

1. 같은 Supabase 프로젝트의 SQL Editor에서 `supabase_cafe_schema.sql`을 한 번 실행합니다.
   (여러 번 실행해도 안전합니다.)
2. 따로 설정할 값은 없습니다. `index.html`이 이미 같은 프로젝트를 쓰고 있습니다.
3. 실행하기 전에는 카페 화면이 **미리보기 모드**로 열리고, 샘플 글이 깔린 채
   새 글은 그 브라우저에만 저장됩니다. 테이블을 만들면 자동으로 실제 게시판으로 바뀝니다.

구조:

- `cafe_posts` 글 (`id, board, streamer, title, body, image_url, author, likes, created_at`)
- `cafe_comments` 댓글 (`id, post_id, author, body, created_at`)
- `cafe_post_keys` 삭제용 4자리 비밀번호의 md5 해시. anon 정책이 없어 읽을 수 없습니다.
- `cafe_create_post(...)`, `cafe_delete_post(id, pin)`, `cafe_like(id, delta)` 함수로만 쓰고 지웁니다.

로그인 없이 쓰는 게시판이라 4자리 비밀번호는 남의 글을 실수로 지우지 않게 하는 잠금입니다.
부적절한 글은 Supabase 대시보드의 Table Editor에서 행을 지웁니다.
