# 미디어 첨부 풀스크린 갤러리 (SwipingMediaView)

작성일: 2026-06-13

## 배경

피드 포스트의 이미지 첨부(`imageAttachments`)는 현재 가로 스크롤 썸네일 스트립으로
표시되고, 탭하면 인앱 `SafariView`로 단일 이미지를 연다. 여러 장일 때 스와이프·줌이
안 되어 갤러리 경험이 부족하다.

목표: 미디어 이미지를 탭하면 **SwipingMediaView**(SwiftUI 네이티브 풀스크린 갤러리)로
그 포스트의 이미지 전체를 스와이프·핀치줌으로 볼 수 있게 한다.

## 라이브러리 선택

`jtCodes/SwipingMediaView` (SPM, v2.2.1 / 2024). 선택 이유: SwiftUI 네이티브(UIKit
래핑 불필요), 다중 이미지 스와이프 갤러리 + 핀치줌 기본 지원, 내부적으로 SDWebImage 사용
(앱의 기존 이미지 스택/캐시와 일관). UIKit 기반 hyperoslo/Lightbox(래퍼+별도 로더 필요),
단일 이미지만 지원하고 정체된 Jake-Short/swiftui-image-viewer 대비 우수.

API:
- `SwipingMediaItem(url: String, type: MediaType, title: String? = nil, shouldShowDownloadButton: Bool = false)`
  — `MediaType`: `.image` / `.video` / `.gif`
- `SwipingMediaView(mediaItems: [SwipingMediaItem], isPresented: Binding<Bool>, currentIndex: Binding<Int>, startingIndex: Int)`
- 표시: `.fullScreenCover(isPresented:) { ZStack { SwipingMediaView(...) }.background(BackgroundCleanerView()).ignoresSafeArea(.all) }`

## 범위

- 대상: `image/*` 첨부만 (기존 `imageAttachments` 재사용). 탭 → 풀스크린 갤러리, 탭한
  이미지부터 시작, 좌우 스와이프 + 핀치줌.
- 비대상: 비디오/GIF 재생(라이브러리는 지원하나 이번엔 제외, YAGNI — 후속에 `mediaType`
  매핑만 확장). 다운로드 버튼 비활성(`shouldShowDownloadButton: false`).
- 본문 인라인 링크(`<a>`)는 변경 없이 기존 인앱 `SafariView` 유지. 미디어 스트립의
  **표시**(썸네일)도 그대로, **탭 동작만** Safari→갤러리로 교체.

## 설계

### 1. 의존성 추가

SPM에 `https://github.com/jtCodes/SwipingMediaView.git`를 추가하고 `ruby-news` 타깃에
`SwipingMediaView` 제품을 링크한다. 이는 `project.pbxproj` 변경이므로 **Xcode GUI
(File > Add Package Dependencies…)로 추가**하는 것을 권장한다(수동 pbxproj 편집은 취약).

### 2. `FeedPostRow` 변경

- 상태 추가:
  ```swift
  @State private var lightboxPresented = false
  @State private var lightboxIndex = 0
  ```
- 미디어 스트립의 `ForEach`를 **인덱스 기반**으로 변경(탭한 인덱스가 필요):
  `ForEach(Array(post.imageAttachments.enumerated()), id: \.element.url)` 형태.
- 이미지 탭 동작을 교체: 기존 `.onTapGesture { openURL(attachment.url) }` →
  `.onTapGesture { lightboxIndex = index; lightboxPresented = true }`.
- 갤러리 아이템 매핑(계산 프로퍼티):
  ```swift
  private var mediaItems: [SwipingMediaItem] {
      post.imageAttachments.map {
          SwipingMediaItem(url: $0.url.absoluteString, type: .image, title: $0.name)
      }
  }
  ```
- 행에 `.fullScreenCover(isPresented: $lightboxPresented)`를 부착해
  `SwipingMediaView(mediaItems: mediaItems, isPresented: $lightboxPresented,
  currentIndex: $lightboxIndex, startingIndex: lightboxIndex)`를 표시
  (README의 `ZStack { ... }.background(BackgroundCleanerView()).ignoresSafeArea(.all)` 패턴).

### 3. 변경하지 않는 것

`FeedView`의 `openURL` 가로채기/`SafariView`, 본문 링크 처리, 아바타, 디코딩, 미디어
스트립의 썸네일 표시 모두 그대로. 미디어 이미지 탭만 `openURL` → 갤러리로 바뀐다.

## 테스트 전략

- UI 통합이라 단위 테스트는 제한적. 이미지 추출 로직(`imageAttachments`)은 이미 단위
  테스트가 있으므로 재사용한다.
- 수동(시뮬레이터/실기기):
  - 이미지 탭 → 풀스크린 갤러리, 탭한 이미지부터 표시.
  - 좌우 스와이프로 같은 포스트의 다른 이미지 이동, 핀치 줌, 드래그/닫기 동작.
  - 본문 인라인 링크 탭 → 여전히 인앱 Safari.
  - 길게 스크롤해도 크래시 없음.

## 영향 범위

- 수정: `ruby-news/Features/Feed/FeedPostRow.swift`(탭 동작 + 갤러리 표시), SPM 의존성
  (`project.pbxproj` / `Package.resolved`).
- 신규 파일 없음(SwipingMediaView가 SwiftUI라 래퍼 불필요).
