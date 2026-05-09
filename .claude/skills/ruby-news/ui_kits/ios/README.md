# Ruby-News iOS UI Kit (SwiftUI)

SwiftUI **code snippets** mirroring the web design system. These files are not a runnable Xcode project — drop them into a fresh SwiftUI app target (iOS 17+) and they will compile.

## Files

| File | What it has |
|---|---|
| `RubyNewsApp.swift` | App entry pattern. Dark-first, `.tint(RNColor.brand)`. **NOTE**: 출시 앱은 3탭 (뉴스 / 피드 / 내 정보) 입니다. 키트의 `RootTabView` 4-탭 예시 (홈/검색/지난 글/프로필) 는 `Screens/` 화면을 한 자리에서 보여주기 위한 패턴 참조용 — 정본은 `SKILL.md` "iOS app" 섹션. |
| `RubyNewsTokens.swift` | `RNColor`, `RNFont`, `RNSpacing`, `RNRadius`, `RNMotion`. Hex-encoded sRGB approximations of the OKLCH tokens in `colors_and_type.css`. |
| `RubyNewsComponents.swift` | `RNButton`, `RNBadge`, `RNCard`, `RNAvatar`, `Article` + `ArticleCard`, `CommentRow`, `SummaryPanel`, `ProseCapsule`, `RNField`, `RNTextField`. |
| `Screens/FeedView.swift` | 홈 — list of articles, brand-green 4-px top accent, `.refreshable` pull-to-refresh. |
| `Screens/ArticleDetailView.swift` | 기사 상세 + 핵심 요약 panel + prose capsules + comment thread + composer. Body font size adjustable from the toolbar menu. |
| `Screens/SearchView.swift` | 검색 — `.searchable` modifier, suggested tag pills, no-results state. Also exports `PastArticlesView` (지난 글). |
| `Screens/LoginView.swift` | 로그인 / 회원 가입. |
| `Screens/ProfileView.swift` | 프로필 / 설정. Push toggle, dark-mode lock, **본문 폰트 크기 slider** (the one tweak the user explicitly requested). |
| `MockData.swift` | `MockArticles`, `MockComments` — Korean copy identical to the web mock. |

## Design language

- **HIG base + functional brand-green accent.** Tab bar, system controls, and navigation chrome stay native; brand color appears only where it'd appear on web — primary buttons, active states, focus rings, the 4-px accent under the nav, the `핵심 요약` summary panel, and prose-capsule edges.
- **Dark-first.** `RubyNewsApp` forces `.preferredColorScheme(.dark)`. The token layer resolves a full light theme automatically — drop the modifier if you want system-driven.
- **No emoji, no decorative gradients.** The single approved gradient is the `핵심 요약` panel, matching web.
- **44pt minimum hit target** on all `RNButton` instances.
- **Pull-to-refresh** uses the system spinner via `.refreshable`. No custom Lottie or bouncy spinners — HIG-default.

## Korean copy rules

Same as the web kit: 폴리트 formal register (해요체), no emoji, no marketing fluff. Section labels and button verbs in `MockData.swift` and the views are canonical — copy them verbatim.

## Substitutions / known gaps

- Color values are **sRGB hex approximations** of the OKLCH tokens. They look correct on a P3 display but are not the exact same chroma — if pixel-parity with web matters, swap to `Color(.displayP3, red:..., green:..., blue:...)` and reconvert.
- Type uses the system stack (`SF Pro` + `Apple SD Gothic Neo`). For visual parity with the web's Noto Sans KR, register the bundled `NotoSansKR-Regular/Medium/Bold` and switch the `RNFont.*` factories to `Font.custom("NotoSansKR-...", size:)`.
- Tab-bar item icons are SF Symbols — the closest HIG equivalents to the Heroicons used on web. Keep these; do not import outline web icons into the iOS app. 출시 앱 3탭 정본: 뉴스 (`newspaper`) / 피드 (`person.2`) / 내 정보 (`person.crop.circle`). 검색은 별도 탭이 아니라 뉴스 탭 내부의 `.searchable` 로 제공합니다.
