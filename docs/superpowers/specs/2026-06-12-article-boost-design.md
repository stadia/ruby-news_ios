# Article Boost Design

## Goal

Add native article boost toggling to the news list while updating article like
requests to the current v1 API paths.

## API Contract

- Like: `POST` or `DELETE /api/v1/articles/{slug}/like`
- Boost: `POST` or `DELETE /api/v1/articles/{slug}/boost`
- Both mutations use JWT bearer authentication and retry once after token refresh.
- Article list responses provide:
  - `liked`, `likers_count`
  - `boosted`, `boosts_count`

## Model And Networking

`NewsArticle` decodes `boosted` and `boosts_count`. `APIClient` adds
`boost(articleSlug:)` and `unboost(articleSlug:)`, returning a `BoostResponse`
with the server's final state and count.

The existing like methods move from the legacy `/articles/...` paths to the
documented `/api/v1/articles/...` paths.

## State And UI

`NewsViewModel` receives an injected boost action, matching the existing like
action. Boost toggling updates the selected article optimistically, then applies
the server response. On authentication or network failure it restores the
original article.

`NewsArticleRow` displays a boost button beside the like button using
`arrow.2.squarepath` and the current boost count. The active state uses the
app's brand color. Accessibility labels distinguish boost and boost cancellation.

Errors reuse the existing list-level behavior:

- Authentication failure: `로그인이 필요합니다.`
- Other boost failure: `부스트 처리에 실패했습니다.`

## Verification

Tests cover:

- Decoding `boosted` and `boosts_count`
- V1 like request paths
- Boost and unboost request methods, bearer header, body, and response decoding
- Boost refresh-and-retry behavior through the shared authentication path
- Successful optimistic boost updates
- Rollback on authentication and general failures

No server changes, post boosting, or article-detail UI changes are included.
