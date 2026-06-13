# Feed 본문 인라인 링크 → 인앱 Safari

작성일: 2026-06-13

## 배경

Native Feed의 포스트 `body`는 서버가 `<p>...</p>` 형태의 HTML로 내려준다.
스크롤 크래시(`NSAttributedString` HTML 파서의 중첩 런루프 충돌)를 고치면서
`FeedPost.plainText(fromHTML:)`이 모든 태그를 제거해 평문(`displayBody: String`)으로
렌더하도록 바꿨다. 그 과정에서 `<a href="...">` 앵커의 URL까지 사라져, 본문에 포함된
링크를 열 수 없게 됐다.

목표: 본문 HTML 안의 앵커 링크(`<a href>`)를 보존해, 사용자가 링크를 탭하면
**인앱 Safari(`SFSafariViewController`)** 로 열리게 한다.

## 범위

- 대상: `<a href="...">앵커문구</a>` 형태의 HTML 하이퍼링크 (Trix/ActionText 에디터 링크).
- 비대상: 평문에 맨몸으로 섞인 URL 자동 링크화(data detector)는 하지 않는다 (YAGNI).
- 내부(ruby-news.dev)/외부 링크 구분 없이 모두 인앱 Safari로 연다. Hotwire 분기는
  필요해지면 후속 작업으로 남긴다.

## 설계

### 1. 링크 보존 파싱 (`FeedPost`)

현재의 "태그를 전부 버리는" 변환을 **세그먼트 파서**로 교체한다. HTML body를
`[(text: String, url: URL?)]` 세그먼트 배열로 분해하는 순수 함수를 둔다:

- `<a href="URL">앵커문구</a>` → `(text: 앵커문구(태그 제거·엔티티 디코딩됨), url: URL)`
- 그 외 구간 → `(text: 평문, url: nil)`
- 블록/줄바꿈 태그(`</p>`, `</div>`, `<br>`, `</li>`, `</h1>`..`</h6>`,
  `</blockquote>`)는 기존과 동일하게 개행으로 치환한다.
- 남은 모든 태그는 제거하고, 공통 HTML 엔티티(`&amp; &lt; &gt; &quot; &#39;
  &#x27; &apos; &nbsp;`)를 디코딩한다.
- 줄 단위로 트림하고 빈 줄을 제거하는 정리 규칙은 기존 평문 로직과 동일하게 유지한다.

이 세그먼트 배열 하나로 두 표현을 파생한다:

- `displayBody: String` — 세그먼트 텍스트만 이어 붙인 평문. 기존 동작/테스트 유지
  (접근성·폴백 용도).
- `attributedBody: AttributedString` — `url`이 있는 세그먼트에 `.link` 속성과
  함께 브랜드 그린(`Color.rnBrand`) `foregroundColor` + `.underlineStyle(.single)`를
  부여한 리치 텍스트.

순수 문자열 처리만 사용하므로(런루프를 펌프하는 `NSAttributedString` HTML 파서를
쓰지 않으므로) List 셀 렌더 중 UICollectionView 레이아웃 충돌 크래시가 재발하지 않는다.

엣지 케이스:
- `href`가 비어 있거나 URL로 파싱 불가하면 → 링크 없는 평문 세그먼트로 취급.
- 앵커 내부에 중첩 태그(`<a><strong>x</strong></a>`)가 있으면 → 내부 태그 제거 후
  텍스트만 링크로.
- 같은 본문에 링크가 여러 개면 → 각각 독립 링크 run으로.

### 2. 렌더링 (`FeedPostRow`)

본문 렌더를 `Text(post.displayBody)` → `Text(post.attributedBody)`로 교체한다.
SwiftUI `Text`의 링크 run은 자동으로 탭 가능하며, 탭 시 `openURL` 환경값으로
라우팅된다. 링크가 아닌 본문 영역의 탭은 기존 `onSelected`(post 상세 시트)를 그대로
유지한다 — SwiftUI에서 `Text` 내부 링크 탭이 상위 `onTapGesture`보다 우선 처리되는
것에 의존한다(구현 시 시뮬레이터에서 검증).

### 3. 인앱 Safari (`SafariView` + openURL 가로채기)

- 신규 파일 `ruby-news/Features/Feed/SafariView.swift`:
  `SFSafariViewController`를 감싼 `UIViewControllerRepresentable`.
- `FeedView`의 피드 영역에 `.environment(\.openURL, OpenURLAction { url in ... })`를
  걸어 링크 탭을 가로챈다. http/https URL이면 `@State private var safariURL: URL?`에
  담고 `.handled`를 반환한다. 그 외 스킴은 `.systemAction`을 반환해 시스템 기본 처리에
  맡긴다(`SFSafariViewController`는 http/https만 지원).
- `safariURL`을 `.sheet(item:)`으로 띄워 `SafariView`를 표시한다. 닫으면 피드로 복귀.
  (`URL`을 `Identifiable`로 쓰기 위한 경량 래퍼 사용.)

### 4. 컴포넌트 경계

| 단위 | 책임 | 의존성 |
|------|------|--------|
| `FeedPost` 세그먼트 파서 | HTML → `[(text, url?)]` + `displayBody`/`attributedBody` 파생 | Foundation만 (순수 함수) |
| `FeedPostRow` | 세그먼트 기반 리치 텍스트 렌더, 링크 외 탭은 onSelected | SwiftUI |
| `SafariView` | URL을 `SFSafariViewController`로 표시 | SafariServices |
| `FeedView` | openURL 가로채 인앱 Safari 시트 표시 | SwiftUI |

## 테스트 전략

TDD로 진행하며 순수 파서 로직을 단위 테스트한다 (`FeedPostTests`):

- 앵커 링크의 href가 보존되고 해당 텍스트 run에 `.link` 속성이 붙는다.
- 본문에 링크가 여러 개일 때 각각 올바른 URL이 붙는다.
- 링크 없는 평문은 링크 run 없이 그대로 렌더된다 (회귀: 기존 `displayBody` 동작 유지).
- 엔티티 디코딩·블록 개행이 앵커 텍스트와 주변 평문 모두에 적용된다.
- `href`가 비었거나 잘못된 경우 평문으로 폴백한다.

수동 확인(시뮬레이터, UI라 단위 테스트 불가):
- 링크 탭 → 인앱 Safari 시트 표시, 닫으면 피드 복귀.
- 본문(링크 아닌 영역) 탭 → 기존 post 상세 시트.
- 링크 포함 포스트를 길게 스크롤해도 크래시 없음.

## 영향 범위

- 수정: `FeedPost.swift`(세그먼트 파서로 확장), `FeedPostRow.swift`(`attributedBody`
  렌더), `FeedView.swift`(openURL 가로채기 + Safari 시트).
- 신규: `SafariView.swift`, 파서 단위 테스트.
- 유지: 기존 `displayBody: String`과 그 테스트.
