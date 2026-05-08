# 서버 개발 요청: iOS 앱용 기존 endpoint JSON 응답 계약

## 목적

`ruby-news.kr` iOS 앱은 별도 `/api/v1` namespace 없이 기존 Rails endpoint를 그대로 사용한다. Native 화면은 항상 다음 헤더를 보내 JSON 응답을 요청한다.

```http
Accept: application/json
```

서버는 동일 endpoint에서 HTML/Turbo 요청은 기존 웹 화면을 유지하고, JSON 요청에는 iOS 앱이 소비할 수 있는 안정적인 JSON을 내려준다.

이 문서는 iOS 앱 구현을 위해 서버 쪽에서 확인/제공해야 할 JSON 계약 요청사항이다. iOS 프로젝트에서는 서버 코드를 직접 수정하지 않는다.

## 진행 상태

2026-05-07 현재:

- `GET /articles` with `Accept: application/json`은 로컬 서버에서 `200 OK`와 JSON 응답을 확인했다.
- iOS 앱은 `/articles` 첫 페이지를 Native 뉴스 목록으로 표시한다.
- `/articles` 응답의 `pagination` 객체는 앱에서 디코딩하며, Native 뉴스 목록의 `더 보기` 버튼에 연결했다.
- 2026-05-07 수동 검증: `더 보기` 버튼으로 다음 페이지가 정상 append되는 것을 확인했다.
- iOS 앱은 `/articles?search=...` 검색 UI를 구현했다. 서버 JSON 응답은 curl로 확인했고, 앱 UI 수동 검증도 완료했다.
- `/others`, `/tag/:keyword`, 현재 사용자 확인 endpoint, 좋아요 POST/DELETE JSON 계약은 아직 iOS에서 구현/검증 전이다.

## 공통 요청사항

### 1. JSON 응답 형식

- key는 `snake_case`를 선호한다.
- 날짜는 ISO 8601 문자열을 사용한다.
- URL은 가능하면 absolute URL로 내려준다.
- 인증 필요 endpoint에서 비로그인 상태는 `401 Unauthorized`를 선호한다.
- validation 실패는 `422 Unprocessable Entity`와 에러 메시지를 내려준다.
- pagination은 endpoint마다 가능한 한 동일한 구조를 사용한다.

권장 에러 형식:

```json
{
  "error": {
    "code": "unauthorized",
    "message": "로그인이 필요합니다."
  }
}
```

권장 pagination 형식:

```json
{
  "pagination": {
    "page": 1,
    "next_page": 2,
    "prev_page": null,
    "limit": 20
  }
}
```

`Pagy::Countless`를 사용하는 endpoint는 `next_page`만 있어도 충분하다.

## 필수 endpoint

### 1. 뉴스 목록

```http
GET /articles
Accept: application/json
```

쿼리:

- `page`: 페이지 번호
- `search`: 검색어, optional

사용처:

- iOS 뉴스 탭 Native 목록
- 검색 결과

요청 응답:

```json
{
  "articles": [
    {
      "id": "rails-8-1-released",
      "title": "Rails 8.1 released",
      "summary": "Rails 8.1 주요 변경점 요약...",
      "source_name": "Ruby on Rails Blog",
      "host": "rubyonrails.org",
      "published_at": "2026-05-06T10:00:00Z",
      "article_url": "https://ruby-news.kr/articles/rails-8-1-released",
      "original_url": "https://rubyonrails.org/...",
      "tags": ["Rails", "Release"],
      "likes_count": 12,
      "liked": true,
      "comments_count": 3
    }
  ],
  "pagination": {
    "page": 1,
    "next_page": 2,
    "limit": 20
  },
  "sidebar_tags": [
    { "name": "Rails", "count": 123 }
  ]
}
```

필드 설명:

| Field | Required | 설명 |
|---|---:|---|
| `id` | yes | iOS 식별자. Hotwire 상세 URL에 쓸 수 있는 slug 권장 |
| `title` | yes | 앱 카드 제목. `title_ko` 우선 권장 |
| `summary` | no | 카드 요약. `summary_key.first` 등 |
| `source_name` | no | `site.name` 또는 `user_name` |
| `host` | no | 원문 host |
| `published_at` | no | 정렬/상대 시간 표시 |
| `article_url` | yes | 앱에서 Hotwire 상세로 열 URL |
| `original_url` | no | 원문 URL |
| `tags` | yes | 태그 문자열 배열. 없으면 빈 배열 |
| `likes_count` | yes | 좋아요 수 |
| `liked` | yes | 현재 사용자 좋아요 여부. 비로그인은 false |
| `comments_count` | yes | 댓글 수. 없으면 0 |

현재 서버 코드 참고:

- `ArticlesController#index`
- `Article.kept.confirmed.related.without_toast`
- `liked_article_ids(@articles)` 로 현재 사용자 liked 여부 계산 가능
- `sidebar_tags` 존재

### 2. 기타 뉴스

```http
GET /others
Accept: application/json
```

응답 형식은 `/articles`와 동일하다.

사용처:

- 뉴스 탭 필터 또는 별도 섹션

현재 서버 코드 참고:

- `ArticlesController#others`
- `Article.kept.confirmed.unrelated.without_toast`

### 3. 태그 뉴스

```http
GET /tag/:keyword
Accept: application/json
```

응답 형식은 `/articles`와 동일하되 현재 태그를 포함하면 좋다.

```json
{
  "tag": "Rails",
  "articles": [],
  "pagination": { "page": 1, "next_page": null, "limit": 20 }
}
```

주의:

- iOS는 `:keyword`를 URL encode해서 보낸다.
- 한글/공백/특수문자 태그 처리 확인 필요.

현재 서버 코드 참고:

- `ArticlesController#tag`
- 라우트 constraints: `keyword: /[^\/]+/`

### 4. 기사 좋아요

현재 iOS Native 뉴스 목록에서는 좋아요 POST/DELETE를 직접 호출하지 않는다. 목록은 `liked`/`likers_count` 표시만 하고, 좋아요 토글은 기사 상세 Hotwire 화면의 기존 Turbo form에 위임한다.

서버 JSON 계약 확인값:

```http
POST /articles/:article_id/like
Accept: application/json
Content-Type: application/x-www-form-urlencoded

authenticity_token=<csrf-token>&likeable_type=Article
```

성공 응답:

```json
{
  "likeable_type": "Article",
  "likeable_slug": "rails-8-1-released",
  "liked": true,
  "likes_count": 13
}
```

### 5. 기사 좋아요 취소

```http
DELETE /articles/:article_id/like
Accept: application/json
Content-Type: application/x-www-form-urlencoded

authenticity_token=<csrf-token>&likeable_type=Article
```

성공 응답:

```json
{
  "likeable_type": "Article",
  "likeable_slug": "rails-8-1-released",
  "liked": false,
  "likes_count": 12
}
```

현재 서버 코드 참고:

- `LikesController#create`
- `LikesController#destroy`
- Hotwire 화면 내 form submit은 Turbo가 CSRF 토큰을 자동 첨부하므로 iOS에서 별도 처리하지 않는다.

### 6. 현재 사용자 확인

현재 사용자 확인용 endpoint가 필요하다. 별도 namespace는 쓰지 않되, 기존 endpoint 중 하나가 JSON 요청을 받았을 때 현재 사용자 정보를 반환하도록 정해야 한다.

후보:

```http
GET /account/edit
Accept: application/json
```

또는

```http
GET /@:username
Accept: application/json
```

하지만 iOS 입장에서는 username을 모르는 상태에서 세션 확인이 필요하므로 `/account/edit` JSON 응답이 가장 자연스럽다.

로그인 상태 응답 권장:

```json
{
  "user": {
    "id": 1,
    "username": "jeff",
    "name": "Jeff Dean",
    "email": "jeff@example.com",
    "avatar_url": "https://ruby-news.kr/rails/active_storage/...",
    "profile_url": "https://ruby-news.kr/@jeff"
  }
}
```

비로그인 응답 권장:

```http
401 Unauthorized
```

현재 서버 코드 참고:

- `Users::RegistrationsController#edit`는 인증 필요
- JSON format 처리 추가가 필요할 수 있음

## 세션/쿠키/CSRF 확인 요청

현재 로그인 자체는 Native JSON `POST /login`(`Accept: application/json`)으로 이동했지만, Hotwire 화면은 계속 Devise 쿠키 세션을 사용한다. 따라서 서버 개발 쪽에서 다음을 확인해주면 iOS 구현 리스크가 줄어든다.

### 확인 1. WebView 로그인 쿠키로 JSON 요청 인증 가능 여부 — ✅ 확인 완료

2026-05-07 검증 결과:

- Devise 로그인(`POST /login`) 성공 → `_al_news_session` 쿠키 획득 확인
- 세션 쿠키로 `GET /articles` JSON 요청 시 서버가 인식함 (session dump에 `warden.user.user.key` 확인)
- iOS Hotwire Native `Navigator.sessionDidFinishRequest`가 WKWebView 쿠키를 `HTTPCookieStorage.shared`로 자동 복사함
- 따라서 별도 쿠키 bridge 구현 불필요. `URLSession.shared`이 `HTTPCookieStorage.shared`의 쿠키를 자동 사용

`/articles` JSON 응답의 `liked` 필드 포함 확인 완료. Native 목록은 이 값을 표시용으로 사용한다.

### 확인 2. POST/DELETE JSON 요청의 CSRF 처리 — ✅ 방향 확정

2026-05-07/08 검증 결과:

- `POST /articles/:article_id/like` with JSON body → **422 InvalidAuthenticityToken**
- `X-CSRF-Token` 헤더만으로도 현재 서버에서 422 발생
- `application/x-www-form-urlencoded` body에 `authenticity_token=<token>&likeable_type=Article`을 보내면 성공 확인

제품 방향:

- Native 뉴스 목록에서는 좋아요 POST/DELETE를 직접 호출하지 않는다.
- 목록 하트는 `liked`/`likers_count` 표시와 상세 진입 유도만 담당한다.
- 실제 좋아요 토글은 상세 Hotwire 화면의 기존 `button_to`/Turbo form에 위임한다. Turbo가 CSRF 토큰을 자동 첨부한다.
- 따라서 현재 iOS 앱에는 CSRF 토큰 브릿지가 필요하지 않다. 추후 Native toolbar 버튼으로 WebView form submit을 트리거해야 하면 BridgeComponent 패턴을 검토한다.

### 확인 3. Devise timeout/rememberable 정책

앱 세션 유지 UX를 위해 확인 필요:

- rememberable 쿠키가 모바일 WebView에서 유지되는지
- timeout 발생 시 JSON endpoint가 401을 반환하는지
- timeout 후 Hotwire 화면이 로그인으로 redirect되는지

## 2차 endpoint 후보

초기 MVP에는 필수는 아니지만, Native 전환을 위해 나중에 필요할 수 있다.

### 1. 피드 JSON

```http
GET /feed
Accept: application/json
```

현재 `/feed`는 인증 필요이며 `ActivitiesController#feed`에서 `Post` 목록을 렌더링한다.

추후 Native 피드 응답 예시:

```json
{
  "posts": [
    {
      "id": "post-slug",
      "body_html": "<p>...</p>",
      "created_at": "2026-05-06T10:00:00Z",
      "post_url": "https://ruby-news.kr/posts/post-slug",
      "author": {
        "name": "Jeff",
        "username": "jeff",
        "at_address": "@jeff@ruby-news.kr",
        "avatar_url": null,
        "local": true
      },
      "article": {
        "id": "rails-8-1-released",
        "title": "Rails 8.1 released",
        "article_url": "https://ruby-news.kr/articles/rails-8-1-released"
      },
      "likes_count": 3,
      "liked": false,
      "replies_count": 2
    }
  ],
  "pagination": { "next_page": 2, "limit": 20 }
}
```

### 2. 기사 상세 JSON

초기에는 Hotwire Native로 처리하지만, 나중에 Native 상세 전환 시 필요하다.

```http
GET /articles/:id
Accept: application/json
```

필요 필드:

- article detail
- comments tree
- similar articles
- liked state
- original URL

### 3. 프로필 JSON

초기에는 Hotwire Native로 처리하지만, 나중에 Native 프로필 전환 시 필요하다.

```http
GET /@:username
Accept: application/json
```

필요 필드:

- user profile
- actor info
- followers_count
- following_count
- follow status

## 이미 JSON이 있는 것으로 보이는 endpoint

서버 코드 기준 이미 `format.json` 처리가 보이는 endpoint:

- `GET /actors/:id`
- `GET /actors/lookup?account=...`
- `POST /followings`
- `POST /followings/follow`
- `PUT /followings/:id/accept`
- `DELETE /followings/:id`
- `POST /push_subscription`
- `DELETE /push_subscription`

단, iOS에서 쓰기 전 실제 응답 형태와 인증/CSRF 동작 검증이 필요하다.

## iOS 구현 unblock 기준

서버 쪽에서 최소한 아래가 준비되면 iOS Native 뉴스 MVP를 구현할 수 있다.

1. `GET /articles` JSON — ✅ 완료/검증됨 (커서 기반 pagination 포함)
2. `GET /others` JSON — 미검증
3. `GET /tag/:keyword` JSON — 미검증
4. 현재 사용자 확인 JSON endpoint 확정 — ❌ `/account/edit`은 HTML만 반환. 서버 JSON format 추가 필요
5. `POST/DELETE /articles/:id/like` JSON — ❌ CSRF 토큰 필요 확인. JSON format 응답도 서버에 추가 필요
6. WebView 로그인 쿠키 → Native JSON 인증 — ✅ 확인 완료. Hotwire Native 자동 복사
7. JSON POST/DELETE의 CSRF 처리 — ⚠️ CSRF 토큰 필요 확인
8. `/articles` JSON에 `liked` 필드 포함 — ❌ 서버에서 아직 미포함. 비로그인 시 `false`, 로그인 시 실제 값 필요

현재 iOS 앱은 1번으로 Native 뉴스 목록과 무한 스크롤(커서 기반 pagination)을 구현했다. 다음 후보는 좋아요 interaction과 로그인/세션 분기 UI다.
