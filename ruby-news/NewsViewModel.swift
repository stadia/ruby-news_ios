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

    private let loadArticles: LoadArticles
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

    init(apiClient: APIClient = APIClient()) {
        self.loadArticles = { cursor, searchQuery, tag in
            if let tag {
                try await apiClient.tag(keyword: tag, cursor: cursor)
            } else {
                try await apiClient.articles(cursor: cursor, searchQuery: searchQuery)
            }
        }
    }

    init(_ loadArticles: @escaping LoadArticles) {
        self.loadArticles = loadArticles
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

