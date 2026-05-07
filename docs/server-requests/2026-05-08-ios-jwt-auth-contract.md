# 서버 요청: iOS Native JSON 요청용 JWT 인증 계약

## 목적

현재 iOS 앱은 Hotwire Native 화면에서는 Devise 쿠키 세션을 그대로 사용하고, Native SwiftUI 화면에서는 `Accept: application/json`으로 기존 endpoint를 호출한다.

좋아요처럼 Native에서 직접 POST/DELETE를 호출해야 하는 기능은 Rails CSRF 정책 때문에 쿠키 세션만으로는 안정적으로 처리하기 어렵다. 서버가 JWT 인증을 지원하면 iOS Native JSON 요청은 `Authorization: Bearer <token>`을 사용하고, Hotwire 화면은 기존 쿠키 세션을 유지하는 하이브리드 구조로 간다.

## 기본 원칙

- Hotwire Native 화면: 기존 Devise 쿠키 세션 유지
- Native JSON 요청: `Authorization: Bearer <access_token>` 사용
- Native 요청은 계속 기존 endpoint를 사용하고 `/api/v1` namespace는 만들지 않는다
- Native 요청은 항상 `Accept: application/json`
- JWT 인증 JSON 요청은 CSRF 검증 대상에서 제외하거나 `null_session`으로 처리한다

## 필요한 서버 계약

### 1. 현재 사용자 + JWT 발급

권장 endpoint:

```http
GET /account/edit
Accept: application/json
```

로그인 상태 응답:

```json
{
  "user": {
    "id": 1,
    "email": "stadia@gmail.com",
    "name": "jeff",
    "username": "jeff",
    "avatar_url": "https://ruby-news.kr/..."
  },
  "auth": {
    "access_token": "jwt...",
    "token_type": "Bearer",
    "expires_at": "2026-05-08T12:00:00Z"
  }
}
```

비로그인 응답:

```http
401 Unauthorized
```

```json
{ "error": "로그인이 필요합니다." }
```

비고:

- iOS는 Hotwire `/login` 성공 후 `/account/edit` JSON을 호출해 `user`와 `access_token`을 갱신한다.
- `expires_at`은 optional이지만 있으면 iOS가 만료 전 refresh 판단에 사용할 수 있다.

### 2. 토큰 refresh 또는 재발급

초기 구현은 단순화를 위해 `/account/edit` JSON 재호출로 token 재발급이 가능하면 충분하다.

가능하면 별도 endpoint도 허용:

```http
POST /account/token
Accept: application/json
Authorization: Bearer <old_token>
```

응답:

```json
{
  "auth": {
    "access_token": "new-jwt...",
    "token_type": "Bearer",
    "expires_at": "2026-05-08T13:00:00Z"
  }
}
```

### 3. 좋아요 JSON 요청

JWT 인증 요청 예시:

```http
POST /articles/:article_id/like
Accept: application/json
Content-Type: application/json
Authorization: Bearer <access_token>

{ "likeable_type": "Article" }
```

```http
DELETE /articles/:article_id/like
Accept: application/json
Content-Type: application/json
Authorization: Bearer <access_token>

{ "likeable_type": "Article" }
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

상태 코드:

- POST 성공: `201 Created` 또는 `200 OK`
- DELETE 성공: `200 OK`
- 인증 누락/만료: `401 Unauthorized`
- 권한 없음: `403 Forbidden`
- validation 실패: `422 Unprocessable Entity`

### 4. 인증 적용 범위

JWT 인증이 필요한 Native endpoint:

- `GET /account/edit` JSON: token 발급/현재 사용자 확인
- `POST /articles/:article_id/like`
- `DELETE /articles/:article_id/like`
- 추후 Native feed/post/follow 요청

JWT 인증이 optional인 endpoint:

- `GET /articles` JSON
- `GET /tag/:keyword` JSON
- `GET /others` JSON

optional endpoint는 `Authorization`이 있으면 사용자별 `liked` 값을 계산하고, 없으면 `liked: false`로 내려준다.

## iOS 쪽 기대 동작

1. 앱 시작
   - 저장된 JWT가 있으면 Native JSON 요청에 사용
   - 동시에 `/account/edit` refresh로 사용자/token 상태 확인 가능
2. Hotwire 로그인 성공 후
   - `/account/edit` JSON 호출
   - `CurrentUser`와 JWT를 저장
3. Native 좋아요
   - `Authorization: Bearer`로 POST/DELETE
   - 성공 시 서버 응답으로 `liked`, `likes_count` 반영
   - 401이면 token clear + 로그인 유도
4. 로그아웃
   - Hotwire logout 후 iOS 저장 token/user 삭제

## 보안 요구사항

- JWT는 HTTPS에서만 사용
- iOS는 Keychain에 token 저장
- token 만료/회수 정책 필요
- JWT 인증 요청은 CSRF 보호 대상에서 제외 가능. Bearer token 자체가 인증 수단이므로 쿠키 CSRF와 분리
- 토큰 payload에 민감 정보는 넣지 않는다

## 확인 필요

- JWT 만료 시간
- refresh 방식: `/account/edit` 재발급으로 충분한지, 별도 refresh endpoint가 필요한지
- logout 시 JWT revoke가 필요한지
- `GET /articles`에 Authorization이 있을 때 `liked` 계산이 정상 동작하는지
