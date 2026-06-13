# 피드 media_attachments 계약 (2026-06-13)

`GET /feed` (Accept: application/json) 응답의 각 post 객체에 `media_attachments`가 추가됨.

| 필드 | 타입 | 비고 |
|------|------|------|
| `media_attachments` | array | 첨부 없으면 `[]` |
| `media_attachments[].url` | string | 원본 URL (필수) |
| `media_attachments[].mediaType` | string \| null | 예: `image/jpeg`. 페디버스 원본 그대로 |
| `media_attachments[].name` | string \| null | 대체 텍스트 |

- Image/Document가 섞여 올 수 있으며, 클라이언트가 `mediaType`이 `image/*`인 것만 렌더한다.
- 서버 구현: `PostSerializer#media_attachments` (al_news), 스웨거 스키마 `spec/requests/feed_spec.rb`.
- 클라이언트: `FeedPost.mediaAttachments`(lossy 디코딩) / `imageAttachments` 필터, `FeedPostRow` 가로 스크롤 이미지 스트립, 탭 시 인앱 `SafariView`.
