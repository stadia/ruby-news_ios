# 피드 이미지 첨부 표시 (서버 + 클라이언트)

작성일: 2026-06-13

## 배경

Native Feed의 포스트는 페디버스(Mastodon 등)에서 들어온 이미지 첨부를 가질 수 있다.
서버 `al_news`의 `posts.media_attachments`(jsonb 컬럼)에
`[{ "url", "mediaType", "name" }, ...]` 형태로 저장된다(`Post.from_activitypub_object`,
`db/schema.rb`). 그러나 피드 JSON을 만드는 `PostSerializer`가 이 컬럼을 직렬화하지
않아, iOS 앱은 이미지 데이터를 전혀 받지 못한다. 결과적으로 피드에 이미지가 보이지 않는다.

(네이티브 피드 최초 설계 `2026-06-13-native-feed-design.md`에서 첨부는 의도적으로 범위
밖이었다. 이번 변경으로 이미지 첨부 표시를 추가한다.)

목표: 서버가 `media_attachments`를 피드 JSON에 포함하고, 클라이언트가 이미지 첨부를
가로 스크롤 스트립으로 렌더하며, 탭하면 원본 이미지를 인앱 Safari로 연다.

## 범위

- 대상: `mediaType`이 `image/*`인 첨부만 렌더한다.
- 비대상: Document(PDF 등) 첨부 렌더, 풀스크린 갤러리/줌, 이미지 업로드. (YAGNI)
- 서버는 jsonb 원본을 그대로 노출하고(범용 유지), 이미지 필터링은 클라이언트가 한다.

## 설계

### 1. 서버 (`al_news`) — 직렬화 필드 추가

`app/serializers/post_serializer.rb`에 `media_attachments` 속성을 추가해 jsonb 컬럼을
그대로 노출한다:

```ruby
attribute :media_attachments do |post|
  post.media_attachments
end
```

응답 형태(피드 JSON의 각 post 객체에 추가):

```json
"media_attachments": [
  { "url": "https://.../img.jpg", "mediaType": "image/jpeg", "name": "대체 텍스트" }
]
```

- 첨부가 없으면 jsonb 기본값에 따라 `[]`.
- Image/Document가 섞여 올 수 있다(서버는 거르지 않는다).
- 계약 문서(`docs/server-requests/`)에 이 필드를 기록한다.

### 2. 클라이언트 모델 (`FeedPost`)

```swift
struct MediaAttachment: Decodable, Equatable, Hashable {
    let url: URL
    let mediaType: String?
    let name: String?
}
```

- `FeedPost`에 `let mediaAttachments: [MediaAttachment]` 추가. `init(from:)`에서
  `decodeIfPresent` 후 `?? []`로 기본값 처리. `APIClient.decoder`가
  `.convertFromSnakeCase`이므로 `media_attachments` ↔ `mediaAttachments` 자동 매핑.
- 개별 첨부의 `url`이 유효하지 않으면 그 항목만 건너뛴다(잘못된 한 항목이 포스트 전체
  디코딩을 깨지 않도록, lossy 디코딩). 구현은 각 요소를 `try?`로 디코딩해 `compactMap`.
- 계산 프로퍼티:
  ```swift
  var imageAttachments: [MediaAttachment] {
      mediaAttachments.filter { $0.mediaType?.hasPrefix("image/") == true }
  }
  ```
  이미지가 아닌 첨부(Document 등)는 제외한다.

### 3. 클라이언트 뷰 (`FeedPostRow`)

- 본문 `Text` 아래, 좋아요/부스트 액션 바 위에 **가로 스크롤 이미지 스트립**을
  `imageAttachments`가 비어 있지 않을 때만 렌더한다.
  - `ScrollView(.horizontal, showsIndicators: false)` 안에 `HStack`으로 각 이미지를
    `WebImage`(SDWebImageSwiftUI, `ProfileView`의 기존 패턴)로 표시.
  - 고정 높이(약 160pt), `scaledToFill` + `clipped`, 둥근 모서리(약 10pt),
    로딩 중 placeholder(예: 회색 배경 + `ProgressView`).
  - 각 이미지에 `.onTapGesture { openURL(attachment.url) }`. `FeedPostRow`는
    `@Environment(\.openURL) private var openURL`을 사용한다.
- **탭 충돌 방지:** 이미지 스트립은 `onSelected`(post 상세) `.onTapGesture`가 걸린
  내부 `VStack` **바깥**에 형제로 배치한다. 이미지 탭은 Safari로, 본문 영역 탭은
  상세로 분리된다.
- openURL은 `FeedView`가 피드 `List`에 주입한 기존 `OpenURLAction`을 그대로 탄다.
  http/https 가드와 `SafariView` 시트가 이미 있으므로 추가 배선이 없다(기존 인라인 링크
  기능 재사용).
- 접근성: 각 이미지에 `name`이 있으면 `accessibilityLabel`로 사용한다.

### 4. 컴포넌트 경계

| 단위 | 책임 | 의존성 |
|------|------|--------|
| `PostSerializer` (서버) | jsonb `media_attachments`를 JSON에 노출 | Alba |
| `MediaAttachment` / `FeedPost.mediaAttachments` / `imageAttachments` | 첨부 디코딩 + 이미지 필터 | Foundation (순수) |
| `FeedPostRow` 이미지 스트립 | 이미지 가로 스크롤 렌더 + 탭→openURL | SwiftUI, SDWebImageSwiftUI |
| `FeedView` openURL/Safari (기존) | 이미지/링크 URL을 인앱 Safari로 | SwiftUI, SafariServices |

## 테스트 전략

**클라이언트(TDD, `FeedPostTests`):**
- `media_attachments`가 `MediaAttachment` 배열로 디코딩된다.
- 필드가 없으면 `mediaAttachments == []`.
- `imageAttachments`가 `image/*`만 통과시키고 Document 등은 제외한다.
- 잘못된 url 항목은 건너뛰고 유효한 항목만 남는다.

**서버(TDD, `al_news`):**
- 피드 JSON(또는 `PostSerializer`) 스펙에 `media_attachments`가 포함되고, 첨부가 있는
  포스트에서 `url`/`mediaType`/`name`이 그대로 직렬화된다.

**수동(시뮬레이터):**
- 이미지 첨부가 있는 페디버스 포스트가 가로 스크롤 스트립으로 보인다.
- 이미지 탭 → 인앱 Safari로 원본 열림, 닫으면 피드 복귀.
- 본문(이미지 아닌 영역) 탭 → post 상세. 스크롤 크래시 없음.

## 영향 범위

- 서버(`al_news`): `app/serializers/post_serializer.rb`, 계약 문서, 서버 테스트.
- 클라이언트(`ruby-news`): `FeedPost.swift`(모델 + 필터), `FeedPostRow.swift`(이미지
  스트립), 클라이언트 테스트.
- 기존 `displayBody`/링크/`SafariView`/`FeedView` openURL 흐름은 변경하지 않고 재사용.
