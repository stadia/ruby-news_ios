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
    typealias LoadArticles = (Int?, String?) async throws -> ArticlesResponse

    private let loadArticles: LoadArticles
    private var activeSearchQuery: String?

    var articles: [NewsArticle] = []
    var pagination: Pagination?
    var searchQuery = ""
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?

    var canLoadMore: Bool {
        pagination?.nextPage != nil && !isLoading && !isLoadingMore
    }

    init(apiClient: APIClient = APIClient()) {
        self.loadArticles = { page, searchQuery in
            try await apiClient.articles(page: page, searchQuery: searchQuery)
        }
    }

    init(_ loadArticles: @escaping LoadArticles) {
        self.loadArticles = loadArticles
    }

    func load() async {
        await loadFirstPage(searchQuery: activeSearchQuery)
    }

    func search() async {
        activeSearchQuery = normalizedSearchQuery
        await loadFirstPage(searchQuery: activeSearchQuery)
    }

    func loadMore() async {
        guard canLoadMore, let nextPage = pagination?.nextPage else { return }

        isLoadingMore = true
        errorMessage = nil

        do {
            let response = try await loadArticles(nextPage, activeSearchQuery)
            articles.append(contentsOf: response.articles)
            pagination = response.pagination
        } catch {
            errorMessage = "뉴스를 더 불러오지 못했습니다."
        }

        isLoadingMore = false
    }

    private func loadFirstPage(searchQuery: String?) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await loadArticles(nil, searchQuery)
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
