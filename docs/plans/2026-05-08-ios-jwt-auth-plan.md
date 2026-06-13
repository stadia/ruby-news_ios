# iOS JWT 인증 대응 구현 계획

## 최종 방향

- 뉴스 목록은 비로그인도 볼 수 있는 public JSON으로 유지한다.
- 로그인은 **Native SwiftUI 폼**에서 JSON 요청으로 처리한다.
- 회원가입/계정 설정/기사 상세/포스트 상세 같은 기존 Rails/Turbo 흐름은 계속 Hotwire Native를 사용한다.
- 피드 목록과 포스트 좋아요/부스트는 JWT Bearer 기반 Native 요청을 사용한다.
- Native 로그인 응답에서 `Authorization` header의 access token과 body의 `refresh_token`을 함께 저장한다.
- 별도 bootstrap endpoint는 만들지 않는다. 로그인 응답만으로 필요한 token을 모두 확보한다.
- Native mutation(좋아요 등)은 JWT `Authorization: Bearer <access_token>`으로 호출한다.

## 서버 확인 결과

서버가 이미 지원하는 계약:

- `POST /login` + `Accept: application/json`
  - request: JSON body `{ "user": { "email": "...", "password": "..." } }`
  - response header: `Authorization: Bearer <access_token>`
  - response body: `{ "user": {...}, "refresh_token": "..." }`
- `POST /api/v1/auth/refresh`
  - request body: `{ "refresh_token": "..." }`
  - response body: `{ "access_token": "...", "refresh_token": "...", "expires_in": 900 }`
- `/articles`, `/tag/:keyword`, `/others`는 비로그인 public JSON 유지
- `GET /account/edit` JSON으로 현재 사용자 조회 가능

## 현재 구현 상태

완료:

- `AuthSession`, `RefreshTokenResponse`, `TokenStore`, `KeychainTokenStore`, `InMemoryTokenStore`
- `APIClient.login(email:password:)`
- `APIClient.refreshTokens(refreshToken:)`
- `SessionStore.login(email:password:)`
- 앱 시작 시 Keychain token 복원
- `SessionStore.refresh()`의 401 시 token clear
- 프로필 탭 비로그인 상태에서 Native 로그인 화면 진입
- 로그인 관련 unit test 추가

검증 완료:

1. cold launch 이후 `피드`/`계정 설정` 로그인 유지 확인
2. Hotwire 내부 logout 후 Native 프로필 상태 즉시 비로그인 전환 확인
3. Native 좋아요/로그아웃 동작 확인
4. refresh가 실서버에서도 401 → 재시도로 정상 동작하는지 확인
5. 기사 상세 Hotwire 좋아요 동작 확인

## 구현 Phase

### Phase 1 — Native 로그인 완성

- [x] `APIClient.login(email:password:)` 구현
- [x] `SessionStore.login(email:password:)` 구현
- [x] `NativeLoginView` 추가
- [x] access/refresh token Keychain 저장
- [x] 로그인 관련 unit test 추가

성공 기준:

- 로그인 성공 시 `currentUser`와 `AuthSession`이 메모리/Keychain에 저장된다.
- bootstrap endpoint 없이 로그인 직후 필요한 token을 확보한다.

### Phase 2 — 앱 재시작 복원

- [x] 앱 시작 시 저장된 token load
- [x] `SessionStore.refresh()`가 token 기반으로 `/account/edit`를 호출
- [x] 401이면 token clear

성공 기준:

- 앱 재시작 후 저장된 token으로 세션 복원이 가능하다.
- 만료/무효 token이면 자동으로 비로그인 상태로 돌아간다.

### Phase 3 — Refresh 연결

- [x] 보호된 Native 요청에서 401 시 refresh 시도
- [x] refresh 성공 후 원 요청 1회 재시도
- [x] refresh 실패 시 token clear + 로그인 유도
- [x] 동시 401 요청의 refresh single-flight 직렬화

주의:

- public 뉴스 목록은 token이 있으면 Authorization을 보낸다.
- token이 없으면 기존 anonymous 호출을 유지한다.

### Phase 4 — Native 좋아요 재도입

- [x] `APIClient.like(articleSlug:)`
- [x] `APIClient.unlike(articleSlug:)`
- [x] `LikeResponse` 모델
- [x] `NewsViewModel.toggleLike(article:)`
- [x] UI rollback / 로그인 필요 에러 처리

### Phase 5 — Web/Native 세션 동기화

- [x] Native logout 버튼 추가
- [x] `GET /logout` Bearer revoke 연결
- [x] Native logout 시 local token/user clear
- [x] `WebSessionBridge`로 `HTTPCookieStorage.shared` → `WKHTTPCookieStore` 복사
- [x] login/logout 시 Hotwire session change notification broadcast
- [x] 기존 Hotwire 화면 auth 변경 시 `navigator.reload()` 재실행
- [x] 프로필 화면 재노출 시 `refresh()` 재실행으로 기본 동기화
- [x] `_al_news_session` Keychain 저장소 추가
- [x] 앱 시작 시 persisted cookie를 `HTTPCookieStorage.shared`로 복원
- [x] cold launch에서도 Web session이 실제로 유지되는지 수동 검증
- [x] 보호 Hotwire 화면 request 완료 후 cookie-auth `/account/edit` 확인으로 Web logout/desync 감지
- [x] Web logout/desync 감지 시 Native token/user clear broadcast
- [x] 실사용 흐름에서 false positive 없이 자연스럽게 동작하는지 수동 검증

### Phase 6 — JWT refresh retry

- [x] 보호 요청 401 시 `/api/v1/auth/refresh` 호출
- [x] refresh 성공 후 원요청 재시도
- [x] refresh된 token을 `TokenStore`에 저장
- [x] refresh된 token을 `SessionStore.authSession` 메모리 상태에도 반영
- [x] `APIClient.like()` / `SessionStore.refresh()` 경로 테스트 추가
- [x] 실서버에서 access token 만료 상황 수동 검증

## 테스트 전략

- Authorization header parsing
- 로그인 response decoding
- refresh response decoding
- TokenStore save/load/delete
- SessionStore login success/failure
- SessionStore refresh unauthorized clear
- APIClient Authorization header / refresh retry
- NewsViewModel like success/failure/unauthorized

## 수동 검증

- Native 로그인 화면에서 정상 로그인
- 로그인 직후 프로필 정보 표시
- 앱 재시작 후 로그인 상태 복원
- 잘못된 비밀번호 입력 시 에러 표시
- access token 만료 상황에서 refresh 동작
- 로그아웃 후 token 삭제

## 보류/확인 필요

- 로그인 JSON 요청의 `Accept: application/json`/`Content-Type: application/json` 계약이 서버에서 계속 유지되는지
- 로그아웃 시 refresh token revoke 범위
