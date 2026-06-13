import Foundation
import Observation

@MainActor
@Observable
final class FeedViewModel {
    typealias LoadFeed = (String?) async throws -> FeedResponse
    typealias ToggleLike = (String, Bool) async throws -> LikeResponse
    typealias ToggleBoost = (String, Bool) async throws -> BoostResponse

    private let loadFeedAction: LoadFeed
    private let toggleLikeAction: ToggleLike
    private let toggleBoostAction: ToggleBoost

    var posts: [FeedPost] = []
    var pagination: FeedPagination?
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?

    var canLoadMore: Bool {
        pagination?.nextPage != nil && !isLoading && !isLoadingMore
    }

    init(apiClient: APIClient? = nil, tokenStore: TokenStore? = nil) {
        let tokenStore = tokenStore ?? KeychainTokenStore()
        let client = apiClient ?? APIClient.authenticated(tokenStore: tokenStore)

        loadFeedAction = { page in
            try await client.feed(page: page)
        }
        toggleLikeAction = { slug, liked in
            if liked {
                try await client.unlike(postSlug: slug)
            } else {
                try await client.like(postSlug: slug)
            }
        }
        toggleBoostAction = { slug, boosted in
            if boosted {
                try await client.unboost(postSlug: slug)
            } else {
                try await client.boost(postSlug: slug)
            }
        }
    }

    init(
        loadFeed: @escaping LoadFeed,
        toggleLike: @escaping ToggleLike = { _, _ in throw APIError.unauthorized },
        toggleBoost: @escaping ToggleBoost = { _, _ in throw APIError.unauthorized }
    ) {
        loadFeedAction = loadFeed
        toggleLikeAction = toggleLike
        toggleBoostAction = toggleBoost
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await loadFeedAction(nil)
            posts = response.posts
            pagination = response.pagination
        } catch APIError.unauthorized {
            errorMessage = "로그인이 필요합니다."
        } catch APIError.unacceptableStatusCode(401) {
            errorMessage = "로그인이 필요합니다."
        } catch {
            errorMessage = "피드를 불러오지 못했습니다."
        }

        isLoading = false
    }

    func loadMore() async {
        guard canLoadMore, let nextPage = pagination?.nextPage else { return }

        isLoadingMore = true
        errorMessage = nil

        do {
            let response = try await loadFeedAction(nextPage)
            let existingIDs = Set(posts.map(\.id))
            posts.append(contentsOf: response.posts.filter { !existingIDs.contains($0.id) })
            pagination = response.pagination
        } catch APIError.unauthorized {
            errorMessage = "로그인이 필요합니다."
        } catch APIError.unacceptableStatusCode(401) {
            errorMessage = "로그인이 필요합니다."
        } catch {
            errorMessage = "피드를 더 불러오지 못했습니다."
        }

        isLoadingMore = false
    }

    func loadMoreIfNeeded(current post: FeedPost) async {
        let threshold = max(1, posts.count - 5)
        guard let index = posts.firstIndex(where: { $0.id == post.id }),
              index >= threshold else {
            return
        }
        // onAppear 호출 시점에 상태를 즉시 변경하면 SwiftUI List의
        // UICollectionView 레이아웃과 충돌할 수 있으므로, 한 틱 뒤로 미룬다.
        await Task.yield()
        await loadMore()
    }

    func toggleLike(_ post: FeedPost) async {
        guard let slug = post.slug, !slug.isEmpty,
              let index = posts.firstIndex(where: { $0.id == post.id }) else {
            return
        }

        errorMessage = nil
        let originalPost = posts[index]
        posts[index].liked.toggle()
        posts[index].likesCount = max(0, posts[index].likesCount + (posts[index].liked ? 1 : -1))

        do {
            let response = try await toggleLikeAction(slug, originalPost.liked)
            guard let updatedIndex = posts.firstIndex(where: { $0.id == post.id }) else { return }
            posts[updatedIndex].liked = response.liked
            posts[updatedIndex].likesCount = response.likesCount
        } catch {
            restore(originalPost)
            errorMessage = interactionErrorMessage(
                error,
                fallback: "좋아요 처리에 실패했습니다."
            )
        }
    }

    func toggleBoost(_ post: FeedPost) async {
        guard let slug = post.slug, !slug.isEmpty,
              let index = posts.firstIndex(where: { $0.id == post.id }) else {
            return
        }

        errorMessage = nil
        let originalPost = posts[index]
        posts[index].boosted.toggle()
        posts[index].boostsCount = max(0, posts[index].boostsCount + (posts[index].boosted ? 1 : -1))

        do {
            let response = try await toggleBoostAction(slug, originalPost.boosted)
            guard let updatedIndex = posts.firstIndex(where: { $0.id == post.id }) else { return }
            posts[updatedIndex].boosted = response.boosted
            posts[updatedIndex].boostsCount = response.boostsCount
        } catch {
            restore(originalPost)
            errorMessage = interactionErrorMessage(
                error,
                fallback: "부스트 처리에 실패했습니다."
            )
        }
    }

    private func restore(_ post: FeedPost) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index] = post
    }

    private func interactionErrorMessage(_ error: Error, fallback: String) -> String {
        if case APIError.unauthorized = error {
            return "로그인이 필요합니다."
        }
        if case APIError.unacceptableStatusCode(401) = error {
            return "로그인이 필요합니다."
        }
        return fallback
    }
}
