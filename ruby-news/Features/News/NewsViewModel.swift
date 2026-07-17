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
    typealias LoadArticles = (NewsSource, String?, String?, String?) async throws -> ArticlesResponse
    typealias ToggleLike = (NewsArticle) async throws -> LikeResponse
    typealias ToggleBoost = (NewsArticle) async throws -> BoostResponse

    private let loadArticles: LoadArticles
    private let toggleLikeAction: ToggleLike
    private let toggleBoostAction: ToggleBoost
    private var activeSearchQuery: String?
    private var latestFirstPageRequestID: UUID?
    private var interactionRequestIDs: [String: UUID] = [:]

    var articles: [NewsArticle] = []
    var pagination: Pagination?
    var searchQuery = ""
    var selectedTag: String?
    var source: NewsSource = .ruby
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?

    var canLoadMore: Bool {
        pagination?.nextPage != nil && !isLoading && !isLoadingMore
    }

    init(apiClient: APIClient? = nil, tokenStore: TokenStore? = nil) {
        let tokenStore = tokenStore ?? KeychainTokenStore()
        let client = apiClient ?? APIClient.authenticated(tokenStore: tokenStore)

        self.loadArticles = { source, cursor, searchQuery, tag in
            switch source {
            case .ruby:
                if let tag {
                    try await client.tag(keyword: tag, cursor: cursor)
                } else {
                    try await client.articles(cursor: cursor, searchQuery: searchQuery)
                }
            case .others:
                try await client.others(cursor: cursor)
            }
        }
        self.toggleLikeAction = { article in
            if article.liked {
                try await client.unlike(articleSlug: article.slug)
            } else {
                try await client.like(articleSlug: article.slug)
            }
        }
        self.toggleBoostAction = { article in
            if article.boosted {
                try await client.unboost(articleSlug: article.slug)
            } else {
                try await client.boost(articleSlug: article.slug)
            }
        }
    }

    init(loadArticles: @escaping LoadArticles,
         toggleLike: @escaping ToggleLike = { _ in throw APIError.unauthorized },
         toggleBoost: @escaping ToggleBoost = { _ in throw APIError.unauthorized }) {
        self.loadArticles = loadArticles
        self.toggleLikeAction = toggleLike
        self.toggleBoostAction = toggleBoost
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

    func selectSource(_ source: NewsSource) async {
        self.source = source
        selectedTag = nil
        activeSearchQuery = nil
        searchQuery = ""
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
        let firstPageRequestID = latestFirstPageRequestID

        isLoadingMore = true
        errorMessage = nil

        do {
            let response = try await loadArticles(source, nextCursor, activeSearchQuery, selectedTag)
            guard latestFirstPageRequestID == firstPageRequestID else { return }
            articles.append(contentsOf: response.articles)
            pagination = response.pagination
        } catch {
            guard latestFirstPageRequestID == firstPageRequestID else { return }
            errorMessage = "뉴스를 더 불러오지 못했습니다."
        }

        if latestFirstPageRequestID == firstPageRequestID {
            isLoadingMore = false
        }
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
        let requestID = UUID()
        interactionRequestIDs[article.id] = requestID
        var optimisticArticle = originalArticle
        optimisticArticle.liked.toggle()
        optimisticArticle.likersCount += optimisticArticle.liked ? 1 : -1
        optimisticArticle.likersCount = max(0, optimisticArticle.likersCount)
        articles[index] = optimisticArticle

        do {
            let response = try await toggleLikeAction(originalArticle)
            guard interactionRequestIDs[article.id] == requestID,
                  let updatedIndex = articles.firstIndex(where: { $0.id == article.id }) else {
                return
            }
            articles[updatedIndex].liked = response.liked
            articles[updatedIndex].likersCount = response.likesCount
        } catch APIError.unauthorized {
            if restore(originalArticle, requestID: requestID) {
                errorMessage = "로그인이 필요합니다."
            }
        } catch APIError.unacceptableStatusCode(401) {
            if restore(originalArticle, requestID: requestID) {
                errorMessage = "로그인이 필요합니다."
            }
        } catch {
            if restore(originalArticle, requestID: requestID) {
                errorMessage = "좋아요 처리에 실패했습니다."
            }
        }
    }

    func toggleBoost(_ article: NewsArticle) async {
        guard let index = articles.firstIndex(where: { $0.id == article.id }) else { return }

        errorMessage = nil
        let originalArticle = articles[index]
        let requestID = UUID()
        interactionRequestIDs[article.id] = requestID
        var optimisticArticle = originalArticle
        optimisticArticle.boosted.toggle()
        optimisticArticle.boostsCount += optimisticArticle.boosted ? 1 : -1
        optimisticArticle.boostsCount = max(0, optimisticArticle.boostsCount)
        articles[index] = optimisticArticle

        do {
            let response = try await toggleBoostAction(originalArticle)
            guard interactionRequestIDs[article.id] == requestID,
                  let updatedIndex = articles.firstIndex(where: { $0.id == article.id }) else {
                return
            }
            articles[updatedIndex].boosted = response.boosted
            articles[updatedIndex].boostsCount = response.boostsCount
        } catch APIError.unauthorized {
            if restore(originalArticle, requestID: requestID) {
                errorMessage = "로그인이 필요합니다."
            }
        } catch APIError.unacceptableStatusCode(401) {
            if restore(originalArticle, requestID: requestID) {
                errorMessage = "로그인이 필요합니다."
            }
        } catch {
            if restore(originalArticle, requestID: requestID) {
                errorMessage = "부스트 처리에 실패했습니다."
            }
        }
    }
}

extension NewsViewModel {
    private func loadFirstPage() async {
        let requestID = UUID()
        latestFirstPageRequestID = requestID
        interactionRequestIDs.removeAll()
        isLoading = true
        isLoadingMore = false
        errorMessage = nil

        do {
            let response = try await loadArticles(source, nil, activeSearchQuery, selectedTag)
            guard latestFirstPageRequestID == requestID else { return }
            articles = response.articles
            pagination = response.pagination
        } catch {
            guard latestFirstPageRequestID == requestID else { return }
            errorMessage = "뉴스를 불러오지 못했습니다."
        }

        if latestFirstPageRequestID == requestID {
            isLoading = false
        }
    }

    private func restore(_ article: NewsArticle, requestID: UUID) -> Bool {
        guard interactionRequestIDs[article.id] == requestID,
              let index = articles.firstIndex(where: { $0.id == article.id }) else {
            return false
        }
        articles[index] = article
        return true
    }

    private var normalizedSearchQuery: String? {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedQuery.isEmpty ? nil : trimmedQuery
    }
}
