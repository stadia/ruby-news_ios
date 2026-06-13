# 피드 작성자 아바타 표시 (클라이언트)

작성일: 2026-06-13

## 배경

서버 `al_news`는 피드 JSON의 각 post에 `author_avatar_url`(nullable string)을 이미
추가·배포했다. 해석 규칙:

```ruby
post.user&.avatar_url || post.federails_actor&.extensions&.dig("icon", "url")
```

로컬 작성자는 ActiveStorage 아바타, 원격(페디버스)은 actor의 icon URL(best-effort),
둘 다 없으면 `null`. swagger 스키마에도 `author_avatar_url: { type: string, nullable: true }`로
반영됨.

목표: iOS 피드 행에 작성자 아바타를 표시한다. 서버는 완료 상태이므로 **클라이언트만**
구현한다.

## 범위

- 대상: 피드 행 헤더에 원형 아바타 표시. URL이 없거나 로딩 실패 시 플레이스홀더.
- 비대상: 아바타 탭으로 프로필 이동(별도 동작), 이미지 캐싱 정책 변경, 프로필 화면 변경. (YAGNI)

## 설계

### 1. 모델 (`FeedPost`)

`let authorAvatarURL: URL?` 추가:
- `init(from:)`에서 `decodeIfPresent(URL.self, forKey: .authorAvatarURL)`.
- `CodingKeys`에 `case authorAvatarURL` 추가. `APIClient.decoder`가 `.convertFromSnakeCase`이므로
  `author_avatar_url` ↔ `authorAvatarURL` 자동 매핑.
- 값이 없거나 URL로 파싱 불가하면 `nil` (decodeIfPresent가 잘못된 URL 문자열에 대해 throw할
  수 있으므로, 안전하게 `String?`로 받아 `URL(string:)`로 변환하는 방식을 쓴다 — 잘못된
  문자열이 포스트 전체 디코딩을 깨지 않도록).

### 2. 뷰 (`FeedPostRow`)

기존 헤더 `HStack(alignment: .firstTextBaseline)`(작성자명/호스트/시간)을 다음으로 변경:
- 정렬을 `.center`로 바꾸고, **맨 앞에 원형 아바타(44pt)** 를 추가한다.
- 나머지 헤더 요소(이름/호스트/Spacer/시간)는 그대로 유지.
- 아바타는 기존 `onSelected` 탭 영역(헤더를 감싼 inner VStack) 안에 있으므로, 탭하면 기존대로
  post 상세로 이동한다(별도 배선 없음).

아바타 뷰:
- `WebImage(url: post.authorAvatarURL)`(SDWebImageSwiftUI, 기존 패턴) + `scaledToFill`,
  `frame(width:44,height:44)`, `clipShape(Circle())`.
- placeholder: SF Symbol `person.crop.circle.fill`(회색). `WebImage`의 placeholder는 로딩
  중·실패·`nil` URL 모두에서 표시되므로, URL이 없는 작성자도 자연스럽게 플레이스홀더가 나온다.
- 접근성: `accessibilityHidden(true)`(작성자명이 이미 텍스트로 노출되므로 중복 정보).

### 3. 테스트

- **클라이언트(TDD, `FeedPostTests`)**:
  - `author_avatar_url`이 있으면 `authorAvatarURL`로 디코딩.
  - 필드가 없으면 `nil`.
  - 잘못된 URL 문자열이면 `nil`(포스트 디코딩은 성공).
- **수동(시뮬레이터)**: 아바타가 있는 작성자는 사진, 없는 작성자는 person 플레이스홀더,
  헤더 레이아웃 정상, 스크롤 크래시 없음.

## 영향 범위

- 클라이언트: `FeedPost.swift`(필드 추가), `FeedPostRow.swift`(헤더에 아바타), `FeedPostTests.swift`.
- 서버: 변경 없음(이미 배포됨).
