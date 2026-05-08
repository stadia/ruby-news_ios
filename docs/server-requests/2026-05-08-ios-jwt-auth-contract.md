# iOS Native JSON 요청용 JWT 인증 계약

## 확인 결과

iOS는 로그인만 Native JSON으로 처리하고, 이후 보호된 Native 요청은 JWT Bearer 인증을 사용한다.

현재 서버가 이미 지원하는 것:

| 항목 | 결과 |
|---|---|
| Native 로그인 | `POST /login` + `Accept: application/json` |
| access token 전달 | response header `Authorization: Bearer <access_token>` |
| refresh token 전달 | response body `refresh_token` |
| refresh | `POST /api/v1/auth/refresh` |
| public 뉴스 목록 | `/articles`, `/tag/:keyword`, `/others` 비로그인 접근 가능 |
| 현재 사용자 조회 | `GET /account/edit` JSON |

## iOS 최종 제품 방향

- 로그인은 Native SwiftUI 폼 + JSON 요청으로 처리한다.
- 회원가입/계정 설정/기사 상세/피드는 기존 Hotwire Native를 유지한다.
- Native 로그인 응답에서 access token과 refresh token을 모두 읽어 Keychain에 저장한다.
- bootstrap endpoint는 사용하지 않는다.
- Native mutation(좋아요 등)은 `Authorization: Bearer <access_token>`으로 호출한다.

## 로그인 계약

```http
POST /login
Accept: application/json
Content-Type: application/json

{ "user": { "email": "jeff@example.com", "password": "secret" } }
```

성공 응답 헤더:

```http
Authorization: Bearer <access_token>
```

성공 응답 body:

```json
{
  "user": {
    "id": 1,
    "email": "jeff@example.com",
    "name": "Jeff",
    "username": "jeff",
    "avatar_url": null
  },
  "refresh_token": "raw-refresh-token"
}
```

실패 응답:

- `401 Unauthorized`
- body는 기존 Devise JSON 형식 유지 가능

## 현재 사용자 조회 계약

```http
GET /account/edit
Accept: application/json
Authorization: Bearer <access_token>
```

성공 응답 예시:

```json
{
  "user": {
    "id": 1,
    "email": "jeff@example.com",
    "name": "Jeff",
    "username": "jeff",
    "avatar_url": null
  }
}
```

비로그인/무효 token:

```http
401 Unauthorized
```

## Public 뉴스 목록 계약

```http
GET /articles
Accept: application/json
Authorization: Bearer <access_token>   # optional
```

동작:

- Authorization 없음: `200 OK`
- Authorization 있음: `200 OK`, 현재 사용자 기준 `liked` 계산
- token 없음은 401이 아니어야 한다

태그/기타 뉴스도 동일 원칙:

```http
GET /tag/:keyword
GET /others
```

## 보호된 Native mutation

좋아요는 JWT 인증을 사용한다.

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

실패 응답:

- access 누락/만료/변조: `401 { "error": "unauthorized" }`
- validation 실패: `422 ...`

## Refresh 계약

```http
POST /api/v1/auth/refresh
Accept: application/json
Content-Type: application/json

{ "refresh_token": "old-refresh-token" }
```

성공 응답:

```json
{
  "access_token": "new-access-token",
  "refresh_token": "new-refresh-token",
  "expires_in": 900
}
```

실패 응답:

- `401 { "error": "invalid_refresh_token" }`

## 로그아웃

현재 서버 구현 기준:

```http
GET /logout
Accept: application/json
Authorization: Bearer <access_token>
```

성공 시 iOS는 Keychain의 access/refresh token과 current user cache를 삭제한다.

## iOS 동작 요약

1. 비로그인 사용자가 Native 로그인 화면에서 이메일/비밀번호 입력
2. `POST /login` 호출 (`Accept: application/json`)
3. response header에서 access token 추출
4. response body에서 `refresh_token`과 `user` 추출
5. Keychain 저장 후 Native 세션 상태를 로그인으로 전환
6. 이후 Native 요청은 Bearer token 사용
7. 401이면 refresh 후 1회 재시도, 실패 시 token clear
