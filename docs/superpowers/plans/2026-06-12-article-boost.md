# Article Boost Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add native article boost toggling and move article like mutations to the documented v1 API paths.

**Architecture:** Extend the existing article model and API client with boost state and mutations. Reuse `NewsViewModel`'s optimistic update and rollback pattern, then expose the action through `NewsArticleRow`.

**Tech Stack:** SwiftUI, Observation, URLSession, Swift Testing, Mocker

---

### Task 1: Decode Boost State

**Files:**
- Modify: `ruby-newsTests/TestHelpers.swift`
- Modify: `ruby-newsTests/NewsArticleTests.swift`
- Modify: `ruby-news/Features/News/NewsArticle.swift`

- [ ] Add a decoding test asserting `boosted == true` and `boostsCount == 4`.
- [ ] Run `xcodebuild ... test -only-testing:ruby-newsTests/NewsArticleTests` and verify compilation fails because boost properties do not exist.
- [ ] Add mutable `boosted: Bool` and `boostsCount: Int` properties with safe defaults matching the existing like fields.
- [ ] Update article test helpers to include configurable boost state.
- [ ] Re-run `NewsArticleTests` and verify they pass.

### Task 2: Add V1 Like And Boost Requests

**Files:**
- Modify: `ruby-newsTests/APIClientTests.swift`
- Modify: `ruby-news/Networking/APIClient.swift`

- [ ] Update like tests to expect `/api/v1/articles/{slug}/like`.
- [ ] Add boost and unboost request tests asserting method, bearer token, JSON body, and decoded response.
- [ ] Add a boost refresh-and-retry test covering the shared `withAuthRetry` path.
- [ ] Run the focused API tests and verify failures for the old like path and missing boost methods.
- [ ] Add `BoostResponse`, `boost(articleSlug:)`, `unboost(articleSlug:)`, and a private boost request helper.
- [ ] Change the like request helper to the v1 path.
- [ ] Re-run `APIClientTests` and verify they pass.

### Task 3: Add Optimistic Boost State

**Files:**
- Modify: `ruby-newsTests/NewsViewModelTests.swift`
- Modify: `ruby-news/Features/News/NewsViewModel.swift`

- [ ] Add tests for successful boost toggling, unauthorized rollback, and general-error rollback.
- [ ] Run the focused ViewModel tests and verify compilation fails because boost injection and toggling do not exist.
- [ ] Add a `ToggleBoost` dependency and default API-backed implementation.
- [ ] Implement optimistic `toggleBoost(_:)`, applying server state on success and restoring the original article on failure.
- [ ] Re-run `NewsViewModelTests` and verify they pass.

### Task 4: Expose Boost In The News Row

**Files:**
- Modify: `ruby-news/Features/News/NewsArticleRow.swift`
- Modify: `ruby-news/Features/News/NewsView.swift`

- [ ] Add `onBoostTapped` to `NewsArticleRow`.
- [ ] Render an `arrow.2.squarepath` button beside like with count, active brand color, and accessibility labels.
- [ ] Wire the row callback to `NewsViewModel.toggleBoost`.
- [ ] Build the app target and verify SwiftLint and compilation pass.

### Task 5: Final Verification

**Files:**
- Modify: `docs/NEXT_SESSION.md`
- Modify: `docs/plans/2026-05-06-ruby-news-ios-app-design.md`
- Modify: `docs/server-requests/2026-05-06-ios-json-contract-requests.md`
- Modify: `docs/server-requests/2026-05-08-ios-jwt-auth-contract.md`

- [ ] Update stale API paths and record native boost support.
- [ ] Run all `ruby-newsTests`.
- [ ] Run an iOS Simulator build.
- [ ] Run `git diff --check` and review the final diff for unrelated changes.
