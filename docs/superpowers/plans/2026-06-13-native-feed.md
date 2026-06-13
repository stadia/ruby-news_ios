# Native Feed Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the authenticated Hotwire feed with a native SwiftUI feed that supports loading, pagination, post like and boost toggles, and Hotwire post detail.

**Architecture:** Add feed-specific decoding models and API methods, then isolate list behavior in `FeedViewModel`. `FeedView` keeps the existing session gate and renders a native `FeedPostRow`; row selection presents the existing Hotwire post route.

**Tech Stack:** SwiftUI, Observation, URLSession, Swift Testing, Mocker, Hotwire Native

---

### Task 1: Decode Feed Responses

**Files:**
- Create: `ruby-news/Features/Feed/FeedPost.swift`
- Create: `ruby-newsTests/FeedPostTests.swift`
- Modify: `ruby-newsTests/TestHelpers.swift`

- [ ] Add a decoding test for all documented feed fields, nullable relationships, post type, interaction state, and `boosted_by`.
- [ ] Run `xcodebuild ... test -only-testing:ruby-newsTests/FeedPostTests` and verify it fails because feed models do not exist.
- [ ] Add `FeedPostType`, `FeedPost`, `FeedResponse`, and `FeedPagination` with snake-case decoding through `APIClient.decoder`.
- [ ] Add focused test helpers for feed posts and responses.
- [ ] Re-run `FeedPostTests` and verify they pass.

### Task 2: Add Feed And Post Interaction Requests

**Files:**
- Modify: `ruby-news/Networking/APIClient.swift`
- Modify: `ruby-newsTests/APIClientTests.swift`

- [ ] Add tests asserting `GET /feed`, optional `page`, JSON Accept header, bearer token, response decoding, and refresh retry.
- [ ] Add post like/unlike and boost/unboost tests asserting `/api/v1/posts/{slug}` paths, HTTP methods, request bodies, and decoded final state.
- [ ] Run focused `APIClientTests` and verify failures for the missing methods.
- [ ] Implement `feed(page:)` through `withAuthRetry`.
- [ ] Generalize private like and boost request helpers to accept `Article` or `Post` paths and body types without changing public article behavior.
- [ ] Add public post mutation overloads with explicit `postSlug` labels.
- [ ] Re-run `APIClientTests` and verify they pass.

### Task 3: Implement Feed State

**Files:**
- Create: `ruby-news/Features/Feed/FeedViewModel.swift`
- Create: `ruby-newsTests/FeedViewModelTests.swift`

- [ ] Add tests for first-page replacement, pagination append, duplicate filtering, near-end loading, first-page failure, and pagination failure.
- [ ] Add tests for optimistic post like and boost success, unauthorized rollback, generic-error rollback, and slug-less no-op behavior.
- [ ] Run focused tests and verify they fail because `FeedViewModel` does not exist.
- [ ] Implement injected load, like, and boost dependencies with default authenticated `APIClient` wiring.
- [ ] Implement initial loading, pagination, near-end triggering, error messages, optimistic updates, and rollback.
- [ ] Re-run `FeedViewModelTests` and verify they pass.

### Task 4: Replace Hotwire Feed List

**Files:**
- Create: `ruby-news/Features/Feed/FeedPostRow.swift`
- Modify: `ruby-news/Features/Feed/FeedView.swift`

- [ ] Add `FeedPostRow` with boost attribution, author metadata, body, context, relative date, like, and boost actions.
- [ ] Replace authenticated `HotwireScreen(.feed)` with a native `List` backed by `FeedViewModel`.
- [ ] Preserve loading, retry, empty, refresh, pagination, and signed-out states.
- [ ] Present `.post(id:)` in a SwiftUI sheet when a row with a slug is selected.
- [ ] Build the app and verify compilation and SwiftLint pass.

### Task 5: Update Product Documentation

**Files:**
- Modify: `docs/NEXT_SESSION.md`
- Modify: `docs/plans/2026-05-06-ruby-news-ios-app-design.md`
- Modify: `docs/server-requests/2026-05-06-ios-json-contract-requests.md`

- [ ] Replace stale statements that Feed is Hotwire-only.
- [ ] Record the implemented `/feed` response and post mutation contracts.
- [ ] Keep creation, reply, deletion, and thread rendering documented as Hotwire flows.
- [ ] Run `git diff --check`.

### Task 6: Final Verification

**Files:**
- Review all changed files

- [ ] Run all `ruby-newsTests`.
- [ ] Build and run the app in the configured iOS Simulator.
- [ ] Verify the signed-in Feed tab renders native controls and no `WKWebView` list.
- [ ] Verify row selection presents Hotwire post detail.
- [ ] Verify the signed-out state remains the existing Native login screen.
- [ ] Review `git status`, `git diff --check`, and the final diff for unrelated changes.

