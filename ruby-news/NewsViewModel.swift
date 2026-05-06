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
    private let apiClient: APIClient

    var articles: [NewsArticle] = []
    var isLoading = false
    var errorMessage: String?

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiClient.articles()
            articles = response.articles
        } catch {
            errorMessage = "뉴스를 불러오지 못했습니다."
        }

        isLoading = false
    }
}
