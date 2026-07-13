# AGENTS.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Project Rules: ruby-news iOS App

**This repository is the iOS app for ruby-news.dev.**

Current product direction:
- Build a news-first iOS app with Mastodon/Fediverse-style social interactions.
- Initial tabs are `News`, `Feed`, and `Profile`.
- Prefer Native SwiftUI for high-frequency list UX, especially the news list.
- Use Hotwire Native for complex existing Rails/Turbo flows: article detail, comments, feed, login, signup, account settings, profiles, followers/following, actor lookup/follow.

Server boundary:
- The Rails server lives outside this repo at `~/projects/al_news`.
- Do not modify server code from this iOS project unless the user explicitly asks.
- The app consumes existing server endpoints; do not assume a separate `/api/v1` namespace.
- Native API requests must use `Accept: application/json` against existing endpoints.
- Hotwire Native screens open the same endpoints as HTML/Turbo screens.
- Authentication starts as Devise web login via Hotwire Native, sharing cookie session state with Native JSON requests.

Documentation:
- Before implementation sessions, read:
  - `docs/NEXT_SESSION.md`
  - `docs/plans/2026-05-06-ruby-news-ios-app-design.md`
  - `docs/server-requests/2026-05-06-ios-json-contract-requests.md`
- If architectural decisions change, update the docs in the same change.

## 6. Red/Green TDD for Code Changes

**Write code using red/green TDD whenever behavior changes.**

Default workflow:
1. Red: write or update a failing test that describes the intended behavior.
2. Green: implement the smallest change that makes the test pass.
3. Refactor: clean up only after tests pass, without changing behavior.
4. Verify: run the relevant test command and report the result.

Apply this especially to:
- `APIClient` request/response behavior.
- JSON decoding models.
- `SessionStore` authentication state.
- `NewsViewModel` loading, search, pagination, and like toggling.
- Any bug fix or behavioral change.

If TDD is not practical for a specific UI-only change, state why and use the smallest useful verification instead, such as SwiftUI preview/manual simulator check/UI test.

## 7. 패키지 우선 원칙

**직접 구현 전에 검증된 패키지가 있는지 먼저 확인한다.**

- Keychain 접근 → `KeychainAccess`
- 이미지 로딩/캐싱 → `SDWebImageSwiftUI`
- 네트워크 레이어 등 앱 규모에 비해 과한 경우는 직접 구현 유지.
- 새 기능을 구현하기 전에 "이미 잘 만든 패키지가 있는가?"를 먼저 물어본다.
- 패키지로 해결 가능한 코드를 직접 작성했다면 리팩터링 대상으로 표시한다.

현재 도입된 패키지:
- `HotwireNative` — 웹뷰 네비게이션
- `SDWebImageSwiftUI` — 이미지 로딩/캐싱
- `KeychainAccess` — Keychain 읽기/쓰기
- `SwiftLint` — 코드 품질 (빌드 플러그인)
- `Mocker` (테스트 전용) — 고정 응답 mocking. 새 테스트는 우선 `URLSession.mockerSession()` + `Mock(...).register()` 사용. 동적 시퀀스 응답이 필요한 케이스는 기존 `URLSession.mockSession(handler:)`(per-session ID로 격리됨) 유지.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
