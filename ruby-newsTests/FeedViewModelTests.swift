import Foundation
import Testing
@testable import ruby_news

@MainActor
@Suite(.serialized)
struct FeedViewModelTests {
    @Test
    func loadReplacesPostsAndLoadMoreAppendsUniquePosts() async throws {
        let first = try TestHelpers.makeFeedPost(id: 1, slug: "post-1")
        let duplicate = try TestHelpers.makeFeedPost(id: 1, slug: "post-1")
        let second = try TestHelpers.makeFeedPost(id: 2, slug: "post-2")
        var requestedPages: [String?] = []
        let viewModel = FeedViewModel(loadFeed: { page in
            requestedPages.append(page)
            if page == nil {
                return FeedResponse(
                    posts: [first],
                    pagination: FeedPagination(nextPage: "2", limit: 20)
                )
            }
            return FeedResponse(
                posts: [duplicate, second],
                pagination: FeedPagination(nextPage: nil, limit: 20)
            )
        })

        await viewModel.load()
        await viewModel.loadMore()

        #expect(requestedPages == [nil, "2"])
        #expect(viewModel.posts.map(\.id) == [1, 2])
        #expect(!viewModel.canLoadMore)
    }

    @Test
    func loadMoreIfNeededOnlyTriggersNearEnd() async throws {
        let posts = try (0..<20).map {
            try TestHelpers.makeFeedPost(id: $0, slug: "post-\($0)")
        }
        let extra = try TestHelpers.makeFeedPost(id: 20, slug: "post-20")
        var callCount = 0
        let viewModel = FeedViewModel(loadFeed: { page in
            callCount += 1
            return page == nil
                ? FeedResponse(
                    posts: posts,
                    pagination: FeedPagination(nextPage: "2", limit: 20)
                )
                : FeedResponse(
                    posts: [extra],
                    pagination: FeedPagination(nextPage: nil, limit: 20)
                )
        })

        await viewModel.load()
        await viewModel.loadMoreIfNeeded(current: posts[0])
        #expect(callCount == 1)

        await viewModel.loadMoreIfNeeded(current: posts[19])
        #expect(callCount == 2)
        #expect(viewModel.posts.last?.id == 20)
    }

    @Test
    func loadAndPaginationFailuresUseSeparateMessages() async throws {
        let post = try TestHelpers.makeFeedPost(id: 1, slug: "post-1")
        var shouldFailFirstPage = true
        let viewModel = FeedViewModel(loadFeed: { page in
            if page == nil, shouldFailFirstPage {
                throw APIError.unacceptableStatusCode(500)
            }
            if page == "2" {
                throw APIError.unacceptableStatusCode(500)
            }
            return FeedResponse(
                posts: [post],
                pagination: FeedPagination(nextPage: "2", limit: 20)
            )
        })

        await viewModel.load()
        #expect(viewModel.posts.isEmpty)
        #expect(viewModel.errorMessage == "피드를 불러오지 못했습니다.")

        shouldFailFirstPage = false
        await viewModel.load()
        await viewModel.loadMore()
        #expect(viewModel.posts.map(\.id) == [1])
        #expect(viewModel.errorMessage == "피드를 더 불러오지 못했습니다.")
    }

    @Test
    func toggleLikeAppliesServerState() async throws {
        let post = try TestHelpers.makeFeedPost(id: 1, slug: "post-1", likesCount: 3)
        let viewModel = FeedViewModel(
            loadFeed: { _ in
                FeedResponse(posts: [post], pagination: FeedPagination(nextPage: nil, limit: 20))
            },
            toggleLike: { slug, liked in
                #expect(slug == "post-1")
                #expect(!liked)
                return LikeResponse(
                    likeableType: "Post",
                    likeableSlug: slug,
                    liked: true,
                    likesCount: 4
                )
            }
        )

        await viewModel.load()
        await viewModel.toggleLike(post)

        #expect(viewModel.posts[0].liked)
        #expect(viewModel.posts[0].likesCount == 4)
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func toggleLikeRollsBackOnUnauthorized() async throws {
        let post = try TestHelpers.makeFeedPost(id: 1, slug: "post-1", likesCount: 3)
        let viewModel = FeedViewModel(
            loadFeed: { _ in
                FeedResponse(posts: [post], pagination: FeedPagination(nextPage: nil, limit: 20))
            },
            toggleLike: { _, _ in throw APIError.unauthorized }
        )

        await viewModel.load()
        await viewModel.toggleLike(post)

        #expect(!viewModel.posts[0].liked)
        #expect(viewModel.posts[0].likesCount == 3)
        #expect(viewModel.errorMessage == "로그인이 필요합니다.")
    }

    @Test
    func toggleBoostAppliesServerState() async throws {
        let post = try TestHelpers.makeFeedPost(id: 1, slug: "post-1", boostsCount: 2)
        let viewModel = FeedViewModel(
            loadFeed: { _ in
                FeedResponse(posts: [post], pagination: FeedPagination(nextPage: nil, limit: 20))
            },
            toggleBoost: { slug, boosted in
                #expect(slug == "post-1")
                #expect(!boosted)
                return BoostResponse(
                    boostableType: "Post",
                    boostableSlug: slug,
                    boosted: true,
                    boostsCount: 3
                )
            }
        )

        await viewModel.load()
        await viewModel.toggleBoost(post)

        #expect(viewModel.posts[0].boosted)
        #expect(viewModel.posts[0].boostsCount == 3)
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func toggleBoostRollsBackOnFailure() async throws {
        let post = try TestHelpers.makeFeedPost(
            id: 1,
            slug: "post-1",
            boosted: true,
            boostsCount: 3
        )
        let viewModel = FeedViewModel(
            loadFeed: { _ in
                FeedResponse(posts: [post], pagination: FeedPagination(nextPage: nil, limit: 20))
            },
            toggleBoost: { _, _ in throw APIError.unacceptableStatusCode(500) }
        )

        await viewModel.load()
        await viewModel.toggleBoost(post)

        #expect(viewModel.posts[0].boosted)
        #expect(viewModel.posts[0].boostsCount == 3)
        #expect(viewModel.errorMessage == "부스트 처리에 실패했습니다.")
    }

    @Test
    func sluglessPostDoesNotMutate() async throws {
        let post = try TestHelpers.makeFeedPost(id: 1, slug: nil)
        var interactionCount = 0
        let viewModel = FeedViewModel(
            loadFeed: { _ in
                FeedResponse(posts: [post], pagination: FeedPagination(nextPage: nil, limit: 20))
            },
            toggleLike: { _, _ in
                interactionCount += 1
                throw APIError.unacceptableStatusCode(500)
            },
            toggleBoost: { _, _ in
                interactionCount += 1
                throw APIError.unacceptableStatusCode(500)
            }
        )

        await viewModel.load()
        await viewModel.toggleLike(post)
        await viewModel.toggleBoost(post)

        #expect(interactionCount == 0)
        #expect(viewModel.posts == [post])
        #expect(viewModel.errorMessage == nil)
    }
}
