# Native Feed Design

## Goal

Replace the authenticated `/feed` Hotwire screen with a native SwiftUI feed
while preserving the existing signed-out login experience and Hotwire post
detail flow.

## Scope

The first native feed release includes:

- Authenticated `GET /feed` JSON loading
- Pull to refresh
- Countless pagination using the server's `next_page`
- Native post cards for short, blog, and comment posts
- Boost attribution through `boosted_by`
- Native post like and boost toggles
- Hotwire post detail navigation for posts with a slug
- Existing signed-out `SignedOutView`

Post creation, reply composition, deletion, profile navigation, attachments,
and native thread rendering are not part of this change. Those flows remain
available after opening the Hotwire post detail where the server provides them.

## Considered Approaches

### Recommended: Native list with Hotwire detail

Decode the new feed JSON into focused feed models, render the scrolling list in
SwiftUI, and keep `/posts/:slug` as the detail destination. This improves the
high-frequency feed browsing and interaction path without duplicating the
server's complex thread and composition UI.

### Native read-only list

Render JSON posts but keep like and boost inside Hotwire detail. This is less
implementation work, but it makes the feed feel inconsistent with the native
news list and wastes the newly available post mutation endpoints.

### Fully native social flow

Build list, detail, thread, reply, creation, and deletion together. The current
JSON contract does not expose enough thread, attachment, or mutation data for
that scope, and it would duplicate working Rails/Turbo behavior.

## API Contract

### Feed

`GET /feed?page={page}` with:

```http
Accept: application/json
Authorization: Bearer <access-token>
```

The response contains:

```json
{
  "posts": [],
  "pagination": {
    "next_page": "2",
    "limit": 20
  }
}
```

`next_page` is treated as an opaque string even though the current server uses
countless page numbers.

### Post interactions

- Like: `POST` or `DELETE /api/v1/posts/{slug}/like`
- Boost: `POST` or `DELETE /api/v1/posts/{slug}/boost`

Both use JWT bearer authentication and the existing one-time token refresh and
retry behavior.

## Models

`FeedPost` decodes the server serializer fields:

- `id: Int`
- `slug: String?`
- `body: String`
- `postType: FeedPostType`
- `status: String?`
- `createdAt`, `updatedAt`
- Mutable `likesCount`, `boostsCount`, `liked`, and `boosted`
- `authorName`, `authorHost`
- `articleSlug`, `parentSlug`
- `boostedBy`

The list identity uses the integer `id`; mutations and detail navigation require
a non-empty `slug`. The model exposes display helpers for author and context,
but does not infer missing server relationships.

`FeedResponse` contains `[FeedPost]` and `FeedPagination`.

## Networking

`APIClient.feed(page:)` uses `/feed`, includes the optional `page` query, and
passes through `withAuthRetry`.

Post mutation methods mirror the existing article methods:

- `like(postSlug:)`
- `unlike(postSlug:)`
- `boost(postSlug:)`
- `unboost(postSlug:)`

The existing `LikeResponse` and `BoostResponse` types are reused because their
response shapes are polymorphic and include the final server state.

## State

`FeedViewModel` owns:

- `posts`
- `pagination`
- initial and next-page loading states
- a user-facing error message

Initial load replaces the list. Pagination appends posts and triggers when a
row appears within five items of the end. Duplicate IDs are not appended.

Like and boost actions update optimistically, then apply the server's final
state. Any failure restores the original post. Authentication failures display
`로그인이 필요합니다.`; other failures identify the failed interaction.

Rows without a slug remain readable but disable post detail and mutation
actions because the documented server endpoints require a slug.

## UI

`FeedView` preserves the current session gate:

- Restoring session: progress indicator
- Signed out: `SignedOutView`
- Signed in: native feed

The signed-in feed uses a plain `List` under a `NavigationStack` with the title
`피드`.

Each `FeedPostRow` displays:

- Optional `@boosted_by 님이 부스트함` attribution
- Author name and optional remote host
- Relative creation time
- Plain post body with natural multiline wrapping
- Context label for article comments or replies when available
- Like and boost buttons with counts and active colors

Tapping the non-button portion of a row with a slug presents
`HotwireScreen(route: .post(id: slug))` in a sheet. Buttons use plain button
style so they do not trigger row navigation.

## Error And Empty States

- First-page failure: retryable `ContentUnavailableView`
- Empty feed: `새 피드가 없습니다`
- Pagination failure: inline error while preserving loaded posts
- Mutation failure: inline error while preserving the restored post
- Unauthorized session detected by the API client: login-required message; the
  existing `SessionStore` remains the source of truth for the signed-in shell

## Testing

Swift Testing covers:

- Feed JSON decoding, including nullable fields and boost attribution
- Feed request path, page query, bearer token, and refresh retry
- Post like/unlike and boost/unboost request paths and methods
- First-page replacement, pagination append, near-end triggering, and failure
- Optimistic like and boost success and rollback
- Slug-less posts remaining non-interactive

Simulator verification covers:

- Signed-in Feed tab renders native rows rather than a web view
- Pull to refresh and pagination
- Like and boost visual state changes
- Post row opens Hotwire detail
- Signed-out Feed tab still shows the existing login UI

