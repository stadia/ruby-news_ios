---
name: Ruby News Design System
description: Design system for Ruby-News (ruby-news.kr), a Korean AI Ruby/Rails news hub. Spotify-inspired dark, content-first, restrained green accent. Use this when designing any Ruby-News surface — article lists, article detail with comment threads, login, navigation, error states.
---

# Ruby News Design System

Korean-first developer news product. Dense, technical, professional. **One product, one surface**: a responsive web app — no separate marketing site, no native app shell.

## When to use

- Anything inside `ruby-news.kr` — feed, article detail, comments, login, profile, "그 밖의 뉴스" (off-topic), tag pages.
- Cross-posts and Fediverse share cards that need to feel of-a-piece with the web app.
- Internal admin / moderation views — same tokens, denser layout.

## Where things live

| Path | Use it for |
|---|---|
| `colors_and_type.css` | Source of truth for tokens. Always link this; never hand-pick hex values. |
| `README.md` | Content + visual + iconography fundamentals. Read before designing copy. |
| `ui_kits/web/kit.html` | Working showcase — article list, article detail, login. Open this first to see the kit in motion. |
| `ui_kits/web/Primitives.jsx` | `Button`, `Badge`, `Card`, `Avatar`, `Heading`, `FormField`, `Input`, `TextArea`. |
| `ui_kits/web/Components.jsx` | `Layout` (Nav + Footer), `ArticleCard`, `ArticleHeader`, `Comment`, `CommentForm`, `SummaryPanel`, `ProseCapsule`, `RecentCommentsSidebar`. |
| `ui_kits/web/Icon.jsx` | Heroicons (outline) inlined as React components, plus brand glyphs (Mastodon, X, Slack). |
| `ui_kits/web/kit.css` | Component CSS that consumes the tokens. |
| `ui_kits/web/mock.js` | `MOCK_ARTICLES`, `MOCK_COMMENTS`, `MOCK_RECENT_COMMENTS` — realistic Korean copy for prototypes. |
| `ui_kits/ios/` | SwiftUI code snippets — `RubyNewsTokens.swift`, `RubyNewsComponents.swift`, `Screens/` (Feed, ArticleDetail, Search, Login, Profile), `MockData.swift`. HIG-base + functional brand-green accent, dark-first, tab-bar nav. See `ui_kits/ios/README.md`. |
| `app/` | Imported source from `stadia/ra-news`. Read for ground truth on Phlex components and views. |
| `preview/` | Token + component swatches. The Design System tab consumes these. |

## How to load the kit in a new HTML file

```html
<html lang="ko" class="dark">
  <head>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;700&display=swap">
    <link rel="stylesheet" href="../colors_and_type.css">
    <link rel="stylesheet" href="ui_kits/web/kit.css">
  </head>
  <body>
    <div id="root"></div>
    <!-- React + Babel (pinned + integrity-hashed per house rules) -->
    <script type="text/babel" src="ui_kits/web/Icon.jsx"></script>
    <script type="text/babel" src="ui_kits/web/Primitives.jsx"></script>
    <script type="text/babel" src="ui_kits/web/Components.jsx"></script>
    <script src="ui_kits/web/mock.js"></script>
  </body>
</html>
```

The kit is **dark by default** (`<html class="dark">`). Drop the class for the light theme; tokens flip automatically. Theme is the only mode — no per-component variants.

## Hard rules

- **Korean-first copy.** UI strings, summaries, labels are Korean. Original English titles only as a secondary `h3` under the Korean translation. Brand wordmark stays exactly: `Ruby-News || 루비 AI 뉴스` (literal `||`).
- **Polite formal register, compact.** Examples: `최신 Ruby, Rails 관련 뉴스와 트렌드를 한곳에서 만나보세요`, `정말 삭제하시겠습니까?`. Never marketing fluff or honorific filler.
- **No emoji.** Zero — not in headings, not in errors, not in microcopy. The literal `→` is allowed for "read more" (`읽어보기 →`).
- **Tokens only.** No raw hex, no Tailwind palette classes (`bg-slate-800`, `text-white` are forbidden). Use `var(--brand-solid)`, `var(--text-content)`, etc.
- **Functional brand color.** Green is for primary buttons, the 4-px nav top border, focus rings, the `핵심 요약` panel, prose-capsule accents. Never decorative.
- **Depth from shade, then border, then shadow.** No glassmorphism, no gradients in chrome. The single approved gradient is the `핵심 요약` summary panel.
- **No bounces.** Animation is `150 / 200 / 300ms` with cubic-beziers. Honor `prefers-reduced-motion`.
- **Heroicons (outline)** for all UI icons, 1.5px stroke, 16/20/24px. Custom monochrome glyphs only for Mastodon / X / Slack / RSS.

## Layout grammar

- Site `<nav>` is full-bleed, has a 4-px brand-green top border, sits inside a 1400-px container.
- Article list → 3-col grid desktop, 2-col tablet, 1-col mobile. Cards: `bg-surface` + `border-border-strong` + `rounded-lg` (12px) + `shadow-md` → `hover:shadow-lg`.
- Article detail → 2-column on desktop (`minmax(0, 1fr) 280px`); sidebar drops to last on mobile. Detail surface has `rounded-xl` (16px).
- Footer is a card-shaped panel inside the bottom margin (`m-4 rounded-lg`).

## Voice cheat-sheet (copy these verbatim)

- Section labels: `핵심 요약`, `관련 글들`, `지난 글`, `그 밖의 뉴스`, `발행일`, `작성자`, `최근 댓글`, `태그`.
- Buttons: `로그인`, `회원 가입`, `검색`, `삭제`, `답글`, `댓글 작성`, `읽어보기 →`.
- Empty / loading: `로딩 중...`, `본문으로 건너뛰기`.
- Confirm destructive: `정말 삭제하시겠습니까?`.

## When the kit doesn't have what you need

- Build the new component in the same file shape as `Components.jsx`. Compose `Card` + `Heading` + `Button` rather than redefining chrome.
- If you need a token that doesn't exist, **don't invent a hex value** — ask first, then add it to `colors_and_type.css` so the rest of the system inherits it.
- New iconography: prefer Heroicons (outline) and add to `Icon.jsx` following the existing `<Icon>` wrapper pattern.

## iOS app (SwiftUI)

A native iOS companion lives in `ui_kits/ios/` as **code snippets** (not a runnable Xcode project — drop into a fresh SwiftUI iOS 17+ target).

- **Design language**: HIG base + functional brand-green accent only. Tab bar / navigation chrome stays native; green appears in primary buttons, active states, the 4-px nav accent, the `핵심 요약` panel, and prose-capsule edges.
- **Dark-first** (`.preferredColorScheme(.dark)` in `RubyNewsApp`). Light theme tokens resolve automatically if removed.
- **Tab bar** with 3 tabs (canonical for the shipped iOS app): 뉴스 (`newspaper`) / 피드 (`person.2`) / 내 정보 (`person.crop.circle`). 검색은 별도 탭이 아니라 `뉴스` 탭의 `.searchable` 로 제공합니다. 키트의 `Screens/SearchView.swift` 와 키트 `RubyNewsApp.swift` 의 4-탭 예시 (홈/검색/지난 글/프로필) 는 패턴 참조용이며, 실제 앱 구조와 일치하지 않습니다. SF Symbols 만 사용 — web outline icon 을 iOS 로 가져오지 않습니다.
- **Tokens** in `RubyNewsTokens.swift` mirror `colors_and_type.css` — sRGB hex approximations of the OKLCH values, dynamically resolved per color scheme. For pixel-parity with web, swap to `Color(.displayP3, ...)`.
- **Type** uses the system stack by default. For Noto Sans KR parity, bundle the font and switch the `RNFont` factories to `Font.custom("NotoSansKR-...", size:)`.
- **The user-requested tweak** (article body font size) lives in two places: the `ArticleDetailView` toolbar menu (작게 / 기본 / 크게) and the slider in `ProfileView` settings.
- **Pull-to-refresh** is the system spinner via `.refreshable` — no custom or bouncy spinners. Korean copy rules from this skill apply verbatim to the iOS app.
- **WKWebView / Hotwire 화면은 sheet 가 아닌 NavigationStack push 로 띄웁니다.** iOS 18 에서 sheet 안의 `WKWebView` 가 RBS process-assertion 실패와 함께 즉시 dismiss 되는 회귀가 있어, `HotwireScreen` (기사 상세, 로그인 / 회원가입 / 계정 등) 은 `.navigationDestination(item:)` 또는 `.navigationDestination(for:)` 로 push 합니다. 새 화면 설계 시 동일 정책 유지.

## Substitutions / known gaps

- The kit ships **no photographic imagery**. The product also has none. If a design needs a photo, that's a content decision the user has to make first.
- The light theme is fully token-mapped but the kit showcase opens dark. Toggle `<html class="dark">` to verify both.
- Speaker notes / decks are out of scope here — this is a product system (web + iOS).
