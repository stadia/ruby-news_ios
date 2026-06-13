# Feed 본문 인라인 링크 → 인앱 Safari Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Feed 포스트 본문의 `<a href>` 앵커 링크를 보존해, 탭하면 인앱 Safari(`SFSafariViewController`)로 열리게 한다.

**Architecture:** 기존 `FeedPost.displayBody`(평문)는 그대로 두고, 본문 HTML에서 앵커 링크를 `[FeedLink]`로 추출한다(순수 Foundation). `FeedPostRow`가 `displayBody` 위에 앵커 텍스트를 매칭해 `.link`/색/밑줄 속성을 입힌 `AttributedString`을 만들어 렌더한다. SwiftUI `Text`의 링크 탭은 `openURL` 환경값으로 라우팅되고, `FeedView`가 이를 가로채 `SafariView` 시트를 띄운다.

**Tech Stack:** SwiftUI, Foundation `NSRegularExpression`, `AttributedString`, SafariServices(`SFSafariViewController`), Swift Testing.

설계 문서: `docs/superpowers/specs/2026-06-13-feed-inline-links-design.md`

---

## File Structure

- `ruby-news/Features/Feed/FeedPost.swift` (수정) — `FeedLink` 타입 + `links` / `anchorLinks(fromHTML:)` 순수 파서 추가. `displayBody`/`plainText`/`decodeEntities`는 변경하지 않는다.
- `ruby-news/Features/Feed/FeedPostRow.swift` (수정) — `attributedBody(for:)` 정적 빌더 추가, 본문을 `Text(attributedBody)`로 렌더.
- `ruby-news/Features/Feed/SafariView.swift` (신규) — `SFSafariViewController`를 감싼 `UIViewControllerRepresentable`.
- `ruby-news/Features/Feed/FeedView.swift` (수정) — `openURL` 가로채기 + `SafariView` 시트.
- `ruby-newsTests/FeedPostTests.swift` (수정) — 링크 파서 / attributedBody 빌더 테스트.

테스트 명령(전체 클래스):

```sh
xcodebuild -project ruby-news.xcodeproj -scheme ruby-news \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  test -only-testing:ruby-newsTests/FeedPostTests
```

---

## Task 1: `FeedLink` 모델 + 앵커 링크 파서

**Files:**
- Modify: `ruby-news/Features/Feed/FeedPost.swift`
- Test: `ruby-newsTests/FeedPostTests.swift`

- [ ] **Step 1: 실패하는 테스트 작성**

`ruby-newsTests/FeedPostTests.swift`의 `private func makePost(body:)` 위(또는 `feedPostDecodesNullableFields` 앞)에 추가:

```swift
    @Test
    func linksExtractAnchorHrefAndTextInOrder() throws {
        let post = try makePost(
            body: "<p><a href=\"https://a.com\">A</a> 그리고 <a href='https://b.com'>B</a></p>"
        )

        #expect(post.links == [
            FeedLink(text: "A", url: try #require(URL(string: "https://a.com"))),
            FeedLink(text: "B", url: try #require(URL(string: "https://b.com")))
        ])
    }

    @Test
    func linksIgnoreEmptyHrefAndMissingHref() throws {
        let post = try makePost(body: "<p><a href=\"\">x</a> <a>y</a> 평문</p>")

        #expect(post.links.isEmpty)
    }

    @Test
    func linksDecodeEntitiesInAnchorText() throws {
        let post = try makePost(body: "<p><a href=\"https://x.com\">a &amp; b</a></p>")

        #expect(post.links == [
            FeedLink(text: "a & b", url: try #require(URL(string: "https://x.com")))
        ])
    }

    @Test
    func displayBodyStillKeepsAnchorInnerText() throws {
        let post = try makePost(body: "<p>보세요 <a href=\"https://x.com\">여기</a> 클릭</p>")

        #expect(post.displayBody == "보세요 여기 클릭")
    }
```

- [ ] **Step 2: 테스트 실패 확인**

Run:
```sh
xcodebuild -project ruby-news.xcodeproj -scheme ruby-news \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  test -only-testing:ruby-newsTests/FeedPostTests 2>&1 | tail -20
```
Expected: 컴파일 실패 — `Cannot find 'FeedLink' in scope`, `Value of type 'FeedPost' has no member 'links'`.

- [ ] **Step 3: 최소 구현**

`ruby-news/Features/Feed/FeedPost.swift`에서 `FeedPostType` enum 아래(또는 `FeedPost` 위)에 `FeedLink`를 추가:

```swift
struct FeedLink: Equatable {
    let text: String
    let url: URL
}
```

그리고 `FeedPost`의 `displayBody` 계산 프로퍼티 바로 아래에 추가:

```swift
    /// 본문 HTML의 `<a href="...">텍스트</a>` 앵커를 문서 순서대로 추출한다.
    /// `text`는 `displayBody`에 나타나는 평문과 동일하게 정리된다.
    var links: [FeedLink] {
        Self.anchorLinks(fromHTML: body)
    }

    static func anchorLinks(fromHTML html: String) -> [FeedLink] {
        let pattern = "<a\\b[^>]*?href\\s*=\\s*[\"']([^\"']*)[\"'][^>]*>(.*?)</a>"
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else {
            return []
        }
        let ns = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: ns.length))
        return matches.compactMap { match in
            let rawHref = ns.substring(with: match.range(at: 1))
            let rawText = ns.substring(with: match.range(at: 2))
            let href = plainText(fromHTML: rawHref)
            let text = plainText(fromHTML: rawText)
            guard !text.isEmpty, let url = URL(string: href) else { return nil }
            return FeedLink(text: text, url: url)
        }
    }
```

- [ ] **Step 4: 테스트 통과 확인**

Run:
```sh
xcodebuild -project ruby-news.xcodeproj -scheme ruby-news \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  test -only-testing:ruby-newsTests/FeedPostTests 2>&1 | tail -20
```
Expected: PASS — 신규 4개 테스트 및 기존 `displayBody*` 테스트 모두 통과.

- [ ] **Step 5: 커밋**

```sh
git add ruby-news/Features/Feed/FeedPost.swift ruby-newsTests/FeedPostTests.swift
git commit -m "feat: Feed 본문에서 앵커 링크(FeedLink) 추출"
```

---

## Task 2: `FeedPostRow.attributedBody(for:)` 빌더 + 렌더

**Files:**
- Modify: `ruby-news/Features/Feed/FeedPostRow.swift`
- Test: `ruby-newsTests/FeedPostTests.swift`

- [ ] **Step 1: 실패하는 테스트 작성**

`ruby-newsTests/FeedPostTests.swift` 상단 import에 `import SwiftUI`를 추가하고(이미 있으면 생략), Task 1에서 추가한 테스트 아래에 추가:

```swift
    @Test
    func attributedBodyMarksAnchorTextAsLink() throws {
        let post = try makePost(
            body: "<p>보세요 <a href=\"https://example.com\">여기</a> 클릭</p>"
        )

        let attributed = FeedPostRow.attributedBody(for: post)
        let linkRun = try #require(attributed.runs.first { $0.link != nil })

        #expect(linkRun.link == URL(string: "https://example.com"))
        #expect(String(attributed[linkRun.range].characters) == "여기")
    }

    @Test
    func attributedBodyWithoutLinksHasNoLinkRun() throws {
        let post = try makePost(body: "<p>그냥 평문입니다.</p>")

        let attributed = FeedPostRow.attributedBody(for: post)

        #expect(attributed.runs.allSatisfy { $0.link == nil })
        #expect(String(attributed.characters) == "그냥 평문입니다.")
    }

    @Test
    func attributedBodyMapsMultipleLinksInOrder() throws {
        let post = try makePost(
            body: "<p><a href=\"https://a.com\">first</a> / <a href=\"https://b.com\">second</a></p>"
        )

        let attributed = FeedPostRow.attributedBody(for: post)
        let linkURLs = attributed.runs.compactMap(\.link)

        #expect(linkURLs == [URL(string: "https://a.com"), URL(string: "https://b.com")])
    }
```

- [ ] **Step 2: 테스트 실패 확인**

Run:
```sh
xcodebuild -project ruby-news.xcodeproj -scheme ruby-news \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  test -only-testing:ruby-newsTests/FeedPostTests 2>&1 | tail -20
```
Expected: 컴파일 실패 — `Type 'FeedPostRow' has no member 'attributedBody'`.

- [ ] **Step 3: 최소 구현 — 빌더 추가**

`ruby-news/Features/Feed/FeedPostRow.swift`에서 `contextSystemImage` 계산 프로퍼티 아래, 닫는 `}` 직전에 정적 빌더를 추가:

```swift
    static func attributedBody(for post: FeedPost) -> AttributedString {
        var attributed = AttributedString(post.displayBody)
        var searchStart = attributed.startIndex

        for link in post.links {
            guard let range = attributed[searchStart...].range(of: link.text) else { continue }
            attributed[range].link = link.url
            attributed[range].foregroundColor = .rnBrand
            attributed[range].underlineStyle = .single
            searchStart = range.upperBound
        }

        return attributed
    }
```

- [ ] **Step 4: 본문 렌더를 attributedBody로 교체**

`ruby-news/Features/Feed/FeedPostRow.swift`의 본문 `Text`를 교체:

```swift
                Text(Self.attributedBody(for: post))
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
```

(기존: `Text(post.displayBody)`)

- [ ] **Step 5: 테스트 통과 확인**

Run:
```sh
xcodebuild -project ruby-news.xcodeproj -scheme ruby-news \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  test -only-testing:ruby-newsTests/FeedPostTests 2>&1 | tail -20
```
Expected: PASS — 신규 3개 및 기존 테스트 모두 통과.

- [ ] **Step 6: 커밋**

```sh
git add ruby-news/Features/Feed/FeedPostRow.swift ruby-newsTests/FeedPostTests.swift
git commit -m "feat: Feed 본문 앵커 링크를 AttributedString 링크로 렌더"
```

---

## Task 3: `SafariView` (SFSafariViewController 래퍼)

**Files:**
- Create: `ruby-news/Features/Feed/SafariView.swift`

이 태스크는 UI 래퍼라 단위 테스트가 없다. 빌드 성공으로 검증한다.

- [ ] **Step 1: SafariView 생성**

`ruby-news/Features/Feed/SafariView.swift`:

```swift
import SafariServices
import SwiftUI

/// `SFSafariViewController`를 SwiftUI 시트로 표시하기 위한 래퍼.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
```

- [ ] **Step 2: 빌드 확인**

Run:
```sh
xcodebuild -project ruby-news.xcodeproj -scheme ruby-news \
  -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -10
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 커밋**

```sh
git add ruby-news/Features/Feed/SafariView.swift
git commit -m "feat: SFSafariViewController를 감싼 SafariView 추가"
```

---

## Task 4: `FeedView` openURL 가로채기 + Safari 시트

**Files:**
- Modify: `ruby-news/Features/Feed/FeedView.swift`

이 태스크는 UI 동작이라 단위 테스트가 없다. 빌드 + Task 5의 수동 검증으로 확인한다.

- [ ] **Step 1: Safari 링크 상태 + Identifiable 래퍼 추가**

`ruby-news/Features/Feed/FeedView.swift`의 `FeedView` 안, 기존 `@State private var sheetRoute: FeedSheetRoute?` 아래에 추가:

```swift
    @State private var safariLink: SafariLink?
```

파일 하단의 `FeedSheetRoute` enum 정의 아래에 추가:

```swift
private struct SafariLink: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}
```

- [ ] **Step 2: content(List)에 openURL 가로채기 + Safari 시트 부착**

`content` 계산 프로퍼티의 `List { ... }`에 붙은 modifier 체인(`.listStyle(.plain)` / `.refreshable { ... }` 가 있는 곳) 끝에 다음을 추가:

```swift
            .environment(\.openURL, OpenURLAction { url in
                guard url.scheme == "http" || url.scheme == "https" else {
                    return .systemAction
                }
                safariLink = SafariLink(url: url)
                return .handled
            })
            .sheet(item: $safariLink) { link in
                SafariView(url: link.url)
                    .ignoresSafeArea()
            }
```

즉 다음 형태가 된다:

```swift
            List {
                // ... 기존 내용 ...
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.load()
            }
            .environment(\.openURL, OpenURLAction { url in
                guard url.scheme == "http" || url.scheme == "https" else {
                    return .systemAction
                }
                safariLink = SafariLink(url: url)
                return .handled
            })
            .sheet(item: $safariLink) { link in
                SafariView(url: link.url)
                    .ignoresSafeArea()
            }
```

- [ ] **Step 3: 빌드 확인**

Run:
```sh
xcodebuild -project ruby-news.xcodeproj -scheme ruby-news \
  -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -10
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: 전체 테스트 회귀 확인**

Run:
```sh
xcodebuild -project ruby-news.xcodeproj -scheme ruby-news \
  -destination 'platform=iOS Simulator,name=iPhone 17' test 2>&1 | tail -10
```
Expected: 모든 테스트 통과(exit 0).

- [ ] **Step 5: 커밋**

```sh
git add ruby-news/Features/Feed/FeedView.swift
git commit -m "feat: Feed 링크 탭을 가로채 인앱 Safari로 열기"
```

---

## Task 5: 수동 검증 (시뮬레이터)

**Files:** 없음 (검증 전용)

단위 테스트가 닿지 못하는 UI 동작을 시뮬레이터에서 확인한다. 로그인된 상태에서 링크가 포함된 포스트가 피드에 보여야 한다(없으면 서버에 링크 포함 short 포스트를 하나 작성).

- [ ] **Step 1: 앱 실행**

```sh
xcodebuild -project ruby-news.xcodeproj -scheme ruby-news \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```
이후 시뮬레이터에서 앱을 실행하고 피드 탭으로 이동.

- [ ] **Step 2: 동작 확인 체크리스트**

- [ ] 본문 안의 링크가 브랜드 그린 + 밑줄로 표시된다.
- [ ] 링크를 탭하면 인앱 Safari 시트가 뜨고, 닫으면 피드로 복귀한다.
- [ ] 링크가 **아닌** 본문 영역을 탭하면 기존대로 post 상세 시트가 뜬다.
- [ ] 링크 포함 포스트를 포함해 길게 스크롤해도 크래시가 없다.

- [ ] **Step 3 (조건부): 탭 충돌 폴백**

만약 링크 탭이 동작하지 않고 항상 post 상세(`onSelected`)가 뜬다면, 본문 `Text`를 감싼 `VStack`의 `.onTapGesture(perform: onSelected)`가 링크 탭을 가로채는 것이다. 이 경우 `FeedPostRow`에서 본문 `Text`를 `.onTapGesture`가 걸린 `VStack` **바깥**으로 빼고, 본문 `Text`에는 탭 제스처를 걸지 않는다(작성자/컨텍스트 라벨 영역에만 `onSelected` 유지). 변경 후 다시 빌드·수동 검증하고 커밋한다.

---

## Self-Review 메모

- **스펙 커버리지:** 링크 보존 파싱(Task 1) · 리치 텍스트 렌더(Task 2) · SafariView(Task 3) · openURL 가로채기+시트(Task 4) · 수동 검증(Task 5) 으로 설계의 4개 컴포넌트 + 테스트 전략을 모두 포함.
- **타입 일관성:** `FeedLink(text:url:)`, `FeedPost.links`, `FeedPost.anchorLinks(fromHTML:)`, `FeedPostRow.attributedBody(for:)`, `SafariView(url:)`, `SafariLink` 명칭이 태스크 전체에서 일치.
- **YAGNI:** 평문 URL 자동 링크화·내부/외부 분기·displayBody 재작성은 범위에서 제외(설계대로).
