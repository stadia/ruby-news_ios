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
    typealias LoadArticles = (Int?) async throws -> ArticlesResponse

    private let loadArticles: LoadArticles

    var articles: [NewsArticle] = []
    var pagination: Pagination?
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?

    var canLoadMore: Bool {
        pagination?.nextPage != nil && !isLoading && !isLoadingMore
    }

    init(apiClient: APIClient = APIClient()) {
        self.loadArticles = { page in
            try await apiClient.articles(page: page)
        }
    }

    init(_ loadArticles: @escaping LoadArticles) {
        self.loadArticles = loadArticles
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await loadArticles(nil)
            articles = response.articles
            pagination = response.pagination
        } catch {
            errorMessage = "뉴스를 불러오지 못했습니다."
        }

        isLoading = false
    }

    func loadMore() async {
        guard canLoadMore, let nextPage = pagination?.nextPage else { return }

        isLoadingMore = true
        errorMessage = nil

        do {
            let response = try await loadArticles(nextPage)
            articles.append(contentsOf: response.articles)
            pagination = response.pagination
        } catch {
            errorMessage = "뉴스를 더 불러오지 못했습니다."
        }

        isLoadingMore = false
    }
}
