# iOS JWT 인증 대응 구현 계획

## 목표

서버가 JWT 인증을 지원하면 iOS Native JSON 요청은 `Authorization: Bearer <token>`을 사용한다. Hotwire Native 화면은 기존 Devise 쿠키 세션을 유지한다.

핵심 결과:

- Native 뉴스 목록/세션 조회/좋아요 요청에서 JWT 사용
- JWT는 Keychain에 저장
- 401 응답 시 token clear + 로그인 유도
- 좋아요 Native interaction을 안전하게 재도입 가능

## 비목표

- Native 로그인 폼 구현 안 함
- `/api/v1` namespace 도입 안 함
- Hotwire 화면의 인증 방식을 JWT로 교체하지 않음
- 복잡한 refresh-token rotation은 서버 계약 확정 전 구현하지 않음

## 전제조건

서버 계약 문서: `docs/server-requests/2026-05-08-ios-jwt-auth-contract.md`

서버에서 최소 제공 필요:

1. `/account/edit` JSON이 `user`와 `auth.access_token` 반환
2. JWT Bearer 요청으로 `POST/DELETE /articles/:slug/like` 성공
3. JWT 요청은 CSRF 오류 없이 처리
4. JWT 인증 실패는 `401 Unauthorized` JSON 반환

## 설계

### 모델

```swift
struct AuthToken: Codable, Equatable {
    let accessToken: String
    let tokenType: String
    let expiresAt: Date?
}

struct AccountResponse: Decodable {
    let user: CurrentUser
    let auth: AuthToken?
}
```

### 저장소

`TokenStore` 또는 `KeychainTokenStore`

책임:

- access token 저장/읽기/삭제
- Keychain 사용
- 테스트에서는 in-memory fake 사용

### SessionStore

현재 역할 유지 + token 관리 추가:

- `currentUser`
- `authToken`
- `refresh()` → `/account/edit` 호출 후 user/token 저장
- `clear()` → user/token 삭제
- `isSignedIn`

### APIClient

변경:

- `authTokenProvider: () -> AuthToken?` 주입
- 모든 Native JSON 요청에 token이 있으면 `Authorization: Bearer <token>` 추가
- 401을 명시적 `APIError.unauthorized`로 변환
- POST/DELETE JSON 요청은 `Content-Type: application/json`

### 좋아요

JWT 준비 후 Native 좋아요 interaction 재도입:

- `NewsArticleRow` 하트 버튼 → `NewsViewModel.toggleLike(article)`
- optimistic update
- 성공 응답으로 `liked`, `likesCount` 확정
- 실패 시 rollback
- 401이면 로그인 유도 상태 표시

## 단계별 작업

### Phase 1 — JWT 응답 디코딩

- [ ] `AuthToken` 모델 추가
- [ ] `AccountResponse`에 `auth` 추가
- [ ] `/account/edit` JSON fixture 테스트 업데이트
- [ ] token 없는 구버전 응답도 디코딩 가능하게 할지 결정

검증:

```sh
xcodebuild test -scheme ruby-news -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:ruby-newsTests
```

### Phase 2 — Keychain TokenStore

- [ ] `TokenStore` protocol 추가
- [ ] `KeychainTokenStore` 구현
- [ ] `InMemoryTokenStore` 테스트 helper 구현
- [ ] 저장/읽기/삭제 unit test

성공 기준:

- refresh 후 token 저장
- logout/clear 후 token 삭제

### Phase 3 — APIClient Authorization

- [ ] `APIClient`에 token provider 주입
- [ ] token 존재 시 `Authorization: Bearer <access_token>` 헤더 추가
- [ ] 401 → `APIError.unauthorized`
- [ ] request 생성 테스트 추가

성공 기준:

- `GET /articles`도 token이 있으면 Authorization 포함
- token 없으면 기존처럼 anonymous request

### Phase 4 — SessionStore 통합

- [ ] `SessionStore.refresh()`가 user와 auth token을 같이 저장
- [ ] `SessionStore.clear()`가 Keychain token 삭제
- [ ] 앱 시작 시 저장 token 기반으로 APIClient 구성
- [ ] Hotwire 로그인 후 refresh 트리거 방식 결정

성공 기준:

- 앱 재시작 후 token이 유지됨
- `/account/edit` 401이면 user/token 삭제

### Phase 5 — Native 좋아요 재도입

- [ ] `APIClient.like(articleSlug:)` / `unlike(articleSlug:)` 복원
- [ ] body `{ "likeable_type": "Article" }`
- [ ] Authorization Bearer 포함
- [ ] `LikeResponse`: `likeableType`, `likeableSlug`, `liked`, `likesCount`
- [ ] `NewsViewModel.toggleLike` optimistic update + rollback
- [ ] `NewsArticleRow` 하트 버튼이 직접 토글하도록 변경

성공 기준:

- 로그인 상태에서 Native 목록 좋아요가 서버와 동기화됨
- 비로그인/만료 token 상태에서는 rollback + 로그인 유도

### Phase 6 — 실기기 검증

- [ ] 실기기 Debug baseURL이 `https://ruby-news.kr`인지 확인
- [ ] 로그인 → `/account/edit` token 발급 확인
- [ ] 뉴스 목록 `liked` 표시 확인
- [ ] Native 좋아요 toggle 확인
- [ ] 앱 재시작 후 token 유지 확인
- [ ] logout 후 token 삭제 확인

## 리스크와 결정 필요 사항

### JWT 만료/refresh

서버가 짧은 만료시간을 쓰면 refresh endpoint가 필요할 수 있다. 초기에는 `/account/edit` 재호출로 token 재발급 가능하면 충분하다.

### Hotwire 로그인 완료 감지

로그인 화면은 Hotwire이므로 로그인 성공 시 Native `SessionStore.refresh()`를 호출해야 한다.

후보:

1. URL redirect 감지
2. BridgeComponent 이벤트
3. Profile 탭 진입/앱 foreground 시 refresh

초기 구현은 3번이 가장 단순하다.

### 로그아웃 동기화

Hotwire `/logout` 후 Native token clear가 필요하다. 초기에는 Profile 탭 재진입 시 `/account/edit` 401로 clear해도 된다.

## 테스트 전략

- `AuthToken` decoding
- `TokenStore` save/load/delete
- `APIClient` Authorization header
- `APIClient` 401 mapping
- `SessionStore.refresh` success/401
- `NewsViewModel.toggleLike` success/failure/unauthorized

## 롤백 계획

JWT 연동 중 문제가 있으면 현재 상태로 유지한다.

- Native 목록은 liked/count 표시만 함
- 좋아요 토글은 Hotwire 상세 화면에 위임
- JWT 저장/Authorization 주입 코드는 feature flag 또는 미사용 상태로 둘 수 있음
