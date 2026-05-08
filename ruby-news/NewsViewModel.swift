//
//  NewsViewModel.swift
//  ruby-news
//
//  Created by JEFF.DEAN on 5/7/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class NewsViewModel {
    typealias LoadArticles = (String?, String?, String?) async throws -> ArticlesResponse
    typealias ToggleLike = (NewsArticle) async throws -> LikeResponse

    private let loadArticles: LoadArticles
    private let toggleLikeAction: ToggleLike
    private var activeSearchQuery: String?

    var articles: [NewsArticle] = []
    var pagination: Pagination?
    var searchQuery = ""
    var selectedTag: String?
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?

    var canLoadMore: Bool {
        pagination?.nextPage != nil && !isLoading && !isLoadingMore
    }

    init(apiClient: APIClient = APIClient(), tokenStore: TokenStore = KeychainTokenStore()) {
        var configuredClient = apiClient
        configuredClient.tokenProvider = {
            try? tokenStore.load()
        }
        configuredClient.onTokenRefreshed = { session in
            try? tokenStore.save(session)
        }

        self.loadArticles = { cursor, searchQuery, tag in
            if let tag {
                try await configuredClient.tag(keyword: tag, cursor: cursor)
            } else {
                try await configuredClient.articles(cursor: cursor, searchQuery: searchQuery)
            }
        }
        self.toggleLikeAction = { article in
            if article.liked {
                try await configuredClient.unlike(articleSlug: article.slug)
            } else {
                try await configuredClient.like(articleSlug: article.slug)
            }
        }
    }

    init(loadArticles: @escaping LoadArticles,
         toggleLike: @escaping ToggleLike = { _ in throw APIError.unauthorized }) {
        self.loadArticles = loadArticles
        self.toggleLikeAction = toggleLike
    }

    convenience init(_ loadArticles: @escaping LoadArticles) {
        self.init(loadArticles: loadArticles)
    }

    func load() async {
        await loadFirstPage()
    }

    func search() async {
        selectedTag = nil
        activeSearchQuery = normalizedSearchQuery
        await loadFirstPage()
    }

    func selectTag(_ tag: String) async {
        selectedTag = tag
        activeSearchQuery = nil
        searchQuery = ""
        await loadFirstPage()
    }

    func clearTag() async {
        selectedTag = nil
        await loadFirstPage()
    }

    func loadMore() async {
        guard canLoadMore else { return }
        let nextCursor = pagination?.nextPage

        isLoadingMore = true
        errorMessage = nil

        do {
            let response = try await loadArticles(nextCursor, activeSearchQuery, selectedTag)
            articles.append(contentsOf: response.articles)
            pagination = response.pagination
        } catch {
            errorMessage = "뉴스를 더 불러오지 못했습니다."
        }

        isLoadingMore = false
    }

    func loadMoreIfNeeded(current article: NewsArticle) async {
        let threshold = max(1, articles.count - 5)
        guard let index = articles.firstIndex(where: { $0.id == article.id }) else { return }
        guard index >= threshold else { return }
        await loadMore()
    }

    func toggleLike(_ article: NewsArticle) async {
        guard let index = articles.firstIndex(where: { $0.id == article.id }) else { return }

        errorMessage = nil
        let originalArticle = articles[index]
        var optimisticArticle = originalArticle
        optimisticArticle.liked.toggle()
        optimisticArticle.likersCount += optimisticArticle.liked ? 1 : -1
        optimisticArticle.likersCount = max(0, optimisticArticle.likersCount)
        articles[index] = optimisticArticle

        do {
            let response = try await toggleLikeAction(originalArticle)
            articles[index].liked = response.liked
            articles[index].likersCount = response.likesCount
        } catch APIError.unauthorized {
            articles[index] = originalArticle
            errorMessage = "로그인이 필요합니다."
        } catch APIError.unacceptableStatusCode(401) {
            articles[index] = originalArticle
            errorMessage = "로그인이 필요합니다."
        } catch {
            articles[index] = originalArticle
            errorMessage = "좋아요 처리에 실패했습니다."
        }
    }

    private func loadFirstPage() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await loadArticles(nil, activeSearchQuery, selectedTag)
            articles = response.articles
            pagination = response.pagination
        } catch {
            errorMessage = "뉴스를 불러오지 못했습니다."
        }

        isLoading = false
    }

    private var normalizedSearchQuery: String? {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedQuery.isEmpty ? nil : trimmedQuery
    }
}

