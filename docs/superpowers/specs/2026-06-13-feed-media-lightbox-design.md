# 미디어 첨부 풀스크린 갤러리 (네이티브 SwiftUI)

작성일: 2026-06-13

## 배경

피드 포스트의 이미지 첨부(`imageAttachments`)는 가로 스크롤 썸네일로 표시되고, 탭하면
인앱 `SafariView`로 단일 이미지를 연다. 여러 장일 때 스와이프·줌이 안 되어 갤러리 경험이
부족하다.

목표: 미디어 이미지를 탭하면 **풀스크린 갤러리**로 그 포스트의 이미지 전체를 좌우 스와이프 +
핀치줌으로 볼 수 있게 한다.

## 라이브러리 미사용 결정

처음 후보였던 `SwipingMediaView`는 **SDWebImageSwiftUI 2.x를 요구**해 우리 앱의
**3.x와 충돌**(SPM 해결 불가)하고, 2.x로 다운그레이드하면 기존 `WebImage`(content/placeholder
클로저, `onSuccess/onFailure`) 코드가 깨진다. 따라서 외부 라이브러리 없이, 이미 쓰는
`WebImage`(SDWebImage 3.x)를 재사용하는 **경량 네이티브 SwiftUI 갤러리**를 직접 만든다.
의존성 충돌·중복이 없고 이미지 캐시도 공유된다.

## 범위

- 대상: `image/*` 첨부(`imageAttachments`)만. 탭 → 풀스크린 갤러리, 탭한 이미지부터 시작,
  좌우 스와이프, 핀치/더블탭 줌, 닫기 버튼.
- 비대상: 비디오/GIF, 다운로드, 공유, 드래그-투-디스미스(제스처 충돌 회피 위해 닫기 버튼만).
  (YAGNI)
- 본문 인라인 링크(`<a>`)는 변경 없이 기존 인앱 `SafariView` 유지. 썸네일 스트립 **표시**도
  그대로, **탭 동작만** Safari→갤러리로 교체.

## 설계

### 1. 신규 컴포넌트 (`MediaGalleryView`)

`ruby-news/Features/Feed/MediaGalleryView.swift` (SwiftUI, `import SDWebImageSwiftUI`).

책임: 이미지 URL 배열을 풀스크린 페이지 갤러리로 표시. 자체 dismiss.

```
MediaGalleryView(attachments: [MediaAttachment], startIndex: Int)
```

구성:
- 검정 배경 위 `TabView(selection: $currentIndex)` + `.tabViewStyle(.page(indexDisplayMode: .automatic))`.
- 각 페이지: `ZoomableImageView`(아래) — 한 장을 핀치/더블탭 줌.
- 상단에 닫기(X) 버튼(`@Environment(\.dismiss)` 호출). 작성자 alt-text(`name`)가 있으면
  하단에 캡션 텍스트.
- `currentIndex`는 `@State`로 `startIndex`에서 시작.

### 2. 줌 가능한 이미지 (`ZoomableImageView`)

같은 파일 내 private 서브뷰. 한 장을 표시하고 핀치/더블탭 줌 + 줌 상태에서 드래그 패닝.

- `WebImage(url:)`를 `.resizable().scaledToFit()`로 표시, 로딩 placeholder는 `ProgressView()`.
- `@State scale`, `@State lastScale`, `@State offset`, `@State lastOffset`.
- `MagnificationGesture`: `scale = min(max(lastScale * value, 1), 5)`, onEnded에 `lastScale = scale`.
- 더블탭: `scale`을 1↔2 토글(애니메이션), 1로 돌아갈 때 offset 리셋.
- 드래그 패닝: **`scale > 1`일 때만** `DragGesture`로 offset 이동(onEnded에 `lastOffset = offset`).
  scale == 1이면 패닝 비활성 → `TabView` 페이지 스와이프가 정상 동작(제스처 충돌 회피).
- 페이지가 바뀌면(`currentIndex` 변경) 줌/offset을 1/zero로 리셋.

### 3. `FeedPostRow` 변경

- 상태 추가:
  ```swift
  @State private var galleryPresented = false
  @State private var galleryIndex = 0
  ```
- 미디어 스트립 `ForEach`를 인덱스 기반으로(탭 인덱스 필요):
  `ForEach(Array(post.imageAttachments.enumerated()), id: \.element.url) { index, attachment in ... }`.
- 이미지 탭 동작 교체: `.onTapGesture { openURL(attachment.url) }`
  → `.onTapGesture { galleryIndex = index; galleryPresented = true }`.
- 행에 `.fullScreenCover(isPresented: $galleryPresented) { MediaGalleryView(attachments: post.imageAttachments, startIndex: galleryIndex) }`.

### 4. 변경하지 않는 것

`FeedView`의 `openURL` 가로채기/`SafariView`, 본문 링크 처리, 아바타, 디코딩, 썸네일 표시
모두 그대로. 미디어 이미지 탭만 `openURL` → 갤러리로 바뀐다.

## 테스트 전략

- UI 상호작용(줌/스와이프/dismiss)은 단위 테스트가 어려우므로 **수동 검증**이 주.
- 이미지 추출(`imageAttachments`)은 기존 단위 테스트로 커버됨(재사용).
- 수동(시뮬레이터/실기기):
  - 이미지 탭 → 풀스크린 갤러리, 탭한 이미지부터 표시.
  - 좌우 스와이프로 같은 포스트의 다른 이미지 이동.
  - 핀치/더블탭 줌, 줌 상태에서 패닝, 닫기 버튼으로 복귀.
  - 본문 인라인 링크 탭 → 여전히 인앱 Safari. 길게 스크롤해도 크래시 없음.

## 영향 범위

- 신규: `ruby-news/Features/Feed/MediaGalleryView.swift`.
- 수정: `ruby-news/Features/Feed/FeedPostRow.swift`(탭 동작 + fullScreenCover).
- 의존성/서버 변경 없음.
