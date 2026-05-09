# Ruby News Design System

Design system for **Ruby-News (루비-뉴스)** — `ruby-news.kr` — an AI-powered Korean Ruby/Rails news hub. Translates and summarizes news from RSS feeds, newsletters, YouTube, and Hacker News, then publishes through the Fediverse.

> **Source code**: [stadia/ra-news](https://github.com/stadia/ra-news) — main branch · Rails 8 · Phlex · RubyUI · Tailwind v4
> **Source-of-truth design doc**: [`DESIGN.md`](https://github.com/stadia/ra-news/blob/main/DESIGN.md) (imported and synthesized below)
> **Live**: <https://ruby-news.kr>

---

## Index

| File | What it has |
|---|---|
| `README.md` | This file — overview, content + visual + iconography fundamentals |
| `colors_and_type.css` | All design tokens: OKLCH colors (dark + light), type scale, spacing, radii, shadows, motion |
| `SKILL.md` | Agent Skill manifest for use as a Claude Skill |
| `assets/` | Logos, icons, OG image |
| `fonts/` | Noto Sans KR loading instructions (CDN-loaded — no local file) |
| `preview/` | Card HTML files used by the Design System tab |
| `ui_kits/web/` | Web app UI kit — JSX recreations of layout, article card, comment thread, post detail, login |
| `app/` | Imported source from `stadia/ra-news` for reference (tokens.css, Phlex components, views) |

---

## Product context

Ruby-News is **one product, one surface**: a responsive web app at `ruby-news.kr` (no separate mobile app, no marketing site). It is built for Korean Ruby/Rails developers who want a single feed of:

- AI-summarized articles from RSS, Gmail newsletters, YouTube transcripts, and Hacker News
- Korean-language summaries + bullet-point key takeaways
- Vector-similarity recommendations between articles
- Threaded comments (discussion lives on the article)
- Federated social presence via Mastodon/ActivityPub (`@news_kr@ruby.social`) and cross-posts to X and Slack

The visual atmosphere is **Spotify-inspired dark by default** — near-black canvas, content-first dense layout, restrained green accent, scan-friendly Korean typography. A light theme exists and is fully token-mapped.

---

## CONTENT FUNDAMENTALS

### Language & locale

The product is **Korean-first** (`locale: ko_KR`, `lang="ko"`). All UI strings, summaries, and section labels are Korean. English is preserved verbatim only for:

- Original article titles (shown as a secondary `h3` beneath the Korean translation)
- Source URLs and code/commands
- Brand names ("Ruby-News || 루비 AI 뉴스")

### Voice & tone

- **Functional, not chatty.** Section labels are nouns: `핵심 요약`, `관련 글들`, `지난 글`, `그 밖의 뉴스`, `발행일`, `작성자`. Buttons are verbs: `로그인`, `회원 가입`, `검색`, `삭제`, `답글`, `읽어보기 →`.
- **Polite formal register** (해요체) but compact — never honorific filler. Examples from the codebase:
  - `최신 Ruby, Rails 관련 뉴스와 트렌드를 한곳에서 만나보세요`
  - `정말 삭제하시겠습니까?`
  - `로딩 중...`
  - `본문으로 건너뛰기`
- **Mixed Korean + English code identifiers** read naturally — `Rails 8`, `pgvector`, `RSS 피드`, `Solid Queue` are left in English inside Korean sentences.
- **No marketing fluff.** No exclamation points, no "Welcome to…", no taglines beyond the meta description.

### Casing

- Korean: native (no concept of case).
- English brand: **`Ruby-News`** with the hyphen, often paired as `Ruby-News || 루비 AI 뉴스` (note the literal `||` separator).
- English UI words inside Korean: lowercase as written (`Mastodon`, `Twitter/X`, `Slack 추가`, `RSS 피드`).
- **Avoid uppercase-stretching of Korean** — never `로 그 인` or `LOGIN` for Korean labels.

### Person

- Default to **omitted subject** (Korean idiom). When a subject is needed, use polite second-person `회원님` very sparingly — the codebase mostly uses subject-less imperatives (`검색...`, `로그인`, `이메일을 입력하세요`).
- For destructive confirms: formal `~하시겠습니까?` (`정말 삭제하시겠습니까?`).

### Emoji & symbols

- **No emoji.** Zero usage in UI strings, headings, error pages, or microcopy.
- A literal `→` is used for "read more" links: `읽어보기 →`.
- Pipe `||` is a brand affectation in the wordmark only.

### Vibe

Dense, technical, professional. Imagine a developer-focused Korean newsletter served as a dark Spotify clone: scan-friendly, no decoration for decoration's sake, every line of copy earning its place.

---

## VISUAL FOUNDATIONS

### Color

OKLCH-native (perceptually uniform). All values are tokenized — markup never references a raw palette class. See `colors_and_type.css` for the full set.

- **Brand**: green hue ~150 (`oklch(0.723 0.192 150)`). Used **functionally only** — primary buttons, active nav indicator (the 4-px top border on the `<nav>`), focus rings, the `핵심 요약` summary panel, prose headings. Never decorative.
- **Neutral scale**: 11-step slate (hue ~257), spans `oklch(0.984 0.003 248)` → `oklch(0.129 0.041 265)`.
- **Surface stack** (dark): `bg-app` `oklch(0.145 0 0)` → `bg-surface` `oklch(0.205 0 0)` → `bg-surface-muted` `oklch(0.269 0 0)`. **Depth comes from shade differences first, borders second, shadows last.**
- **Status**: success (lime), warning (amber), error (red), info (blue) — each has both a `*-solid` (button bg) and `*-text` (lighter, foreground-on-dark) variant.

### Type

- **Single family**: `Noto Sans KR`, sans-serif. CDN-loaded with `display=swap`. No serif, no display face.
- **Three weights**: 400 / 500 / 700.
- **Scale**: 12 / 14 / 16 / 18 / 20 / 24 / 30 / 36 / 48 px. Body is 14 px (`text-sm`), body-large is 16 px, page titles are 30 px mobile / 36 px desktop.
- Slightly **looser line-height** for Korean readability (`leading-relaxed` 1.625 on body copy).
- Bold-vs-regular is the primary contrast system. Korean labels avoid all-caps and aggressive tracking.

### Spacing

8 px rhythm with a 4 px micro-step. Tokens: `xs 4 / sm 8 / md 16 / lg 24 / xl 32 / 2xl 48 / 3xl 64 / 4xl 96`. Container max-width is **1400 px**, padding `2rem` inline.

### Backgrounds

- **No imagery**, no full-bleed photo, no hand-drawn illustration, no repeating texture.
- **No gradients in chrome.** The one place a linear gradient appears is the article-detail "핵심 요약" panel (`bg-linear-to-r from-brand-solid to-brand-solid-hover`), and that's it.
- The canvas is a flat near-black; depth is built by stacking surface shades.

### Animation

- **Subtle and short.** Standard durations: `150ms` (fast) / `200ms` (base) / `300ms` (slow).
- **No bounces.** Easings are `ease-in`, `ease-out`, `ease-in-out` (cubic-beziers per spec).
- **Common transitions**: `transition-colors` on hover, `transition-shadow` on cards, `transition-all duration-200` on inputs.
- Mobile menu uses `slide-in-from-top-2 fade-in duration-200`. Loading uses a single `animate-spin` brand-colored border.
- `prefers-reduced-motion: reduce` is honored — durations collapse to `0.01ms`.

### Hover states

- **Cards**: `hover:shadow-lg` (one step up the shadow scale) + `hover:border-border-strong` if they have a muted border.
- **Links**: `hover:text-link-hover` (one step deeper green) and `hover:underline`.
- **Ghost icon buttons**: `hover:bg-surface-muted`.
- **Primary buttons**: `hover:bg-brand-solid-hover` (one step deeper green).
- Pattern: hover always darkens green or lifts the surface stack; never lightens or saturates.

### Press / active states

- Buttons rely on the same color shift as hover. No explicit `:active` shrink/scale.
- Focus rings (keyboard) are visible: `ring-2 ring-brand ring-offset-2 ring-offset-app`.

### Borders

- **Three weights** of border, each tied to a neutral step:
  - `border-strong` — the default visible divider
  - `border-muted` — softer, for inputs / hover-revealed card outlines
  - `border-subtle` — almost invisible, for low-priority sections
- Cards default to `border border-border-strong`. The site `<nav>` has `border-b border-border-strong` plus a **4 px brand-colored top border** (`border-t-4 border-t-brand`) — the strongest single use of brand color in the chrome.

### Shadows

5-step scale: `sm`, `md`, `lg`, `xl`, `2xl`, plus `inner` and two focus-ring presets. Used **only for overlays and floating UI** — popovers, modals, and a card's hover-elevation step. Never to "lift" content that should sit flat.

### Protection / capsules

Long-form prose uses **subtle capsule containers**: rounded panels in `bg-surface-muted` with a 4-px left-border accent in the section's color (`border-l-4 border-state-info` for `도입`, `border-l-4 border-brand` for `결론`). This is the one approved exception to the "no colored left-border cards" rule.

### Layout rules

- **Top nav is fixed-feeling** but technically static — full-bleed bar with the 4-px brand top border.
- **Main is a single 1400-px container** with side gutters; lists become 3-column grids on desktop, 2 on tablet, 1 on mobile.
- **Sidebar** (recent comments + tags) is `lg:w-72`, ordered last on mobile.
- Footer is a card-shaped panel inside the bottom margin (`m-4 rounded-lg bg-surface`).

### Transparency & blur

- **Almost none.** Translucent `bg-app/75` is used once, behind the loading overlay, with no blur.
- No `backdrop-filter`, no glassmorphism. Use opacity sparingly (`/10`, `/20` rings on badges).

### Imagery vibe

There is essentially **no photographic imagery**. The single imported image (`assets/og_main.png`) is the OG share card. If imagery were added, it should be: warm, slightly desaturated, dark-leaning to match the canvas — never bright or full-color brand-stock.

### Corner radii

`sm 6 / md 8 / lg 12 / xl 16 / 2xl 24 / full 9999`. Mapping:

- Buttons → `rounded-lg` (8 px)
- Inputs → `rounded-md` (8 px)
- Cards → `rounded-lg` (12 px)
- Article detail surface → `rounded-xl` (16 px)
- Profile card → `rounded-2xl` (24 px)
- Badges/pills → `rounded-full`

### Card pattern

```
bg-surface
border border-border-strong
rounded-lg (12 px)
shadow-md  →  hover:shadow-lg
padding p-3 md:p-6
transition-shadow / transition-all duration-200/300
```

### Don'ts (lifted from `DESIGN.md`)

- ❌ Hardcoded Tailwind palette classes (`bg-slate-800`, `text-white`).
- ❌ Decorative accent colors outside the token system.
- ❌ Marketing-airy spacing — this is a content product.
- ❌ Color-alone state communication.
- ❌ Primitive tokens used in components (only semantic).

---

## ICONOGRAPHY

The codebase uses **Heroicons** via the `phlex_icons` gem, called as `Hero::Foo(variant: :outline, class: "w-N h-N")`. Outline is the dominant variant; solid is rare.

### Approach

- **Stroke-style line icons**, 1.5 px stroke (Heroicons default).
- Sized in 16 / 20 / 24 px steps (`w-4 h-4`, `w-5 h-5`, `w-6 h-6`).
- Color follows context: `text-content-muted` on metadata rows, `text-brand` on hero accents, `text-brand-foreground` on solid backgrounds.
- A handful of brand SVGs are inlined directly in `app/components/layout.rb` (Mastodon, X, Slack glyphs) — these are simple monochrome paths in `currentColor`.
- **No emoji as icons.** No unicode glyph icons except the `→` arrow for "read more".

### Icon sources used in this design system

We use **Heroicons via CDN** to mirror what the app uses:

```html
<!-- Heroicons SVGs are loaded inline; for prototyping, fetch from the JSON-published set: -->
<!-- https://unpkg.com/heroicons@2.1.5/24/outline/ -->
<!-- e.g. https://unpkg.com/heroicons@2.1.5/24/outline/calendar-days.svg -->
```

For the UI kit we render Heroicons inline as SVGs (so the kit is offline-capable and styleable via `currentColor`). See `ui_kits/web/Icon.jsx`.

### Specific icons used in the product (by location)

- **Article card meta row**: `User`, `ChatBubbleLeftEllipsis`, `CalendarDays`, `Heart` (like)
- **Article detail header**: `User`, `Calendar`, `ArrowTopRightOnSquare` (source URL), `CheckCircle` (summary)
- **Comments**: `Clock`, `Trash`, `ChatBubbleLeft`
- **Nav**: `Bars3` (mobile menu), `Rss`, custom Mastodon/X/Slack glyphs, theme-toggle sun/moon
- **Section headers**: `Newspaper` (`관련 글들`)

### Logos / brand marks

- `assets/icon.svg` — primary app icon (red gradient "D" mark inside a soft cream card with a folded-corner motif). 512 × 512.
- `assets/icon.png`, `icon-192.png`, `apple-touch-icon.png` — raster favicons / PWA icons.
- `assets/og_main.png` — Open Graph share image (1200 × 630).
- The wordmark is **typography-set, not an SVG**: `Ruby-News || 루비 AI 뉴스`, weight 600, with `루비 AI 뉴스` in `text-accent-text` (brand green).

### Substitution flag

Nothing was substituted. Heroicons are used in production and we mirror that exactly.
