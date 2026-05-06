//
//  ruby_newsTests.swift
//  ruby-newsTests
//
//  Created by JEFF.DEAN on 5/6/26.
//

import Foundation
import Testing
@testable import ruby_news

struct ruby_newsTests {

    @MainActor
    @Test func appTabsExposeInitialProductStructure() async throws {
        #expect(AppTab.allCases == [.news, .feed, .profile])
        #expect(AppTab.news.title == "뉴스")
        #expect(AppTab.feed.title == "피드")
        #expect(AppTab.profile.title == "내 정보")
    }

    @MainActor
    @Test func appTabsExposeStableAccessibilityIdentifiers() async throws {
        #expect(AppTab.news.accessibilityIdentifier == "tab.news")
        #expect(AppTab.feed.accessibilityIdentifier == "tab.feed")
        #expect(AppTab.profile.accessibilityIdentifier == "tab.profile")
    }

    @MainActor
    @Test func webRoutesBuildExpectedURLs() async throws {
        let baseURL = try #require(URL(string: "https://ruby-news.kr"))

        #expect(WebRoute.login.url(relativeTo: baseURL).absoluteString == "https://ruby-news.kr/login")
        #expect(WebRoute.feed.url(relativeTo: baseURL).absoluteString == "https://ruby-news.kr/feed")
        #expect(WebRoute.article(id: "rails-8-1").url(relativeTo: baseURL).absoluteString == "https://ruby-news.kr/articles/rails-8-1")
        #expect(WebRoute.profile(username: "matz").url(relativeTo: baseURL).absoluteString == "https://ruby-news.kr/@matz")
    }

    @MainActor
    @Test func webRoutesPercentEncodeDynamicPathSegments() async throws {
        let baseURL = try #require(URL(string: "https://ruby-news.kr"))

        #expect(WebRoute.tag(keyword: "Ruby 뉴스").url(relativeTo: baseURL).absoluteString == "https://ruby-news.kr/tag/Ruby%20%EB%89%B4%EC%8A%A4")
        #expect(WebRoute.profile(username: "ruby_user").url(relativeTo: baseURL).absoluteString == "https://ruby-news.kr/@ruby_user")
    }

    @MainActor
    @Test func articlesRequestUsesExistingEndpointWithJSONAcceptHeader() async throws {
        let baseURL = try #require(URL(string: "http://localhost:3000"))
        let request = APIRequest(path: "/articles").urlRequest(relativeTo: baseURL)

        #expect(request.url?.absoluteString == "http://localhost:3000/articles")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @MainActor
    @Test func articlesRequestEncodesSearchAndPageQuery() async throws {
        let baseURL = try #require(URL(string: "http://localhost:3000"))
        let request = APIRequest(
            path: "/articles",
            queryItems: [
                URLQueryItem(name: "search", value: "rails hotwire"),
                URLQueryItem(name: "page", value: "2")
            ]
        ).urlRequest(relativeTo: baseURL)

        #expect(request.url?.absoluteString == "http://localhost:3000/articles?search=rails%20hotwire&page=2")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @MainActor
    @Test func tagRequestEncodesKeywordPathAndPageQuery() async throws {
        let baseURL = try #require(URL(string: "http://localhost:3000"))
        let request = APIRequest.tag(keyword: "Ruby 뉴스", page: 2).urlRequest(relativeTo: baseURL)

        #expect(request.url?.absoluteString == "http://localhost:3000/tag/Ruby%20%EB%89%B4%EC%8A%A4?page=2")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @MainActor
    @Test func articlesRequestEncodesPageQuery() async throws {
        let baseURL = try #require(URL(string: "http://localhost:3000"))
        let request = APIRequest(
            path: "/articles",
            queryItems: [URLQueryItem(name: "page", value: "2")]
        ).urlRequest(relativeTo: baseURL)

        #expect(request.url?.absoluteString == "http://localhost:3000/articles?page=2")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @MainActor
    @Test func newsViewModelAppendsNextPage() async throws {
        var requestedPages: [Int?] = []
        let responses = [
            1: try articlesResponse(slugs: ["first-page-article"], page: 1, next: 2),
            2: try articlesResponse(slugs: ["second-page-article"], page: 2, next: nil)
        ]
        let viewModel = NewsViewModel { page, searchQuery, tag in
            #expect(searchQuery == nil)
            #expect(tag == nil)
            requestedPages.append(page)
            return try #require(responses[page ?? 1])
        }

        await viewModel.load()
        #expect(viewModel.articles.map(\.id) == ["first-page-article"])
        #expect(viewModel.canLoadMore)

        await viewModel.loadMore()
        #expect(requestedPages == [nil, 2])
        #expect(viewModel.articles.map(\.id) == ["first-page-article", "second-page-article"])
        #expect(!viewModel.canLoadMore)
    }

    @MainActor
    @Test func newsViewModelSearchesAndPaginatesWithQuery() async throws {
        var requests: [(page: Int?, searchQuery: String?, tag: String?)] = []
        let defaultResponse = try articlesResponse(slugs: ["default-article"], page: 1, next: nil)
        let searchFirstPage = try articlesResponse(slugs: ["rails-first-page"], page: 1, next: 2)
        let searchSecondPage = try articlesResponse(slugs: ["rails-second-page"], page: 2, next: nil)
        let viewModel = NewsViewModel { page, searchQuery, tag in
            requests.append((page, searchQuery, tag))

            if searchQuery == "rails" && page == nil {
                return searchFirstPage
            } else if searchQuery == "rails" && page == 2 {
                return searchSecondPage
            } else if searchQuery == nil && page == nil {
                return defaultResponse
            }

            Issue.record("Unexpected request page=\(String(describing: page)) search=\(String(describing: searchQuery))")
            return defaultResponse
        }

        viewModel.searchQuery = "rails"
        await viewModel.search()
        #expect(viewModel.articles.map(\.id) == ["rails-first-page"])
        #expect(viewModel.canLoadMore)

        await viewModel.loadMore()
        #expect(viewModel.articles.map(\.id) == ["rails-first-page", "rails-second-page"])
        #expect(!viewModel.canLoadMore)

        viewModel.searchQuery = ""
        await viewModel.search()
        #expect(viewModel.articles.map(\.id) == ["default-article"])
        #expect(requests.map { $0.page } == [nil, 2, nil])
        #expect(requests.map { $0.searchQuery } == ["rails", "rails", nil])
        #expect(requests.map { $0.tag } == [nil, nil, nil])
    }

    @MainActor
    @Test func newsViewModelFiltersAndPaginatesByTag() async throws {
        var requests: [(page: Int?, searchQuery: String?, tag: String?)] = []
        let tagFirstPage = try articlesResponse(slugs: ["tag-first-page"], page: 1, next: 2)
        let tagSecondPage = try articlesResponse(slugs: ["tag-second-page"], page: 2, next: nil)
        let viewModel = NewsViewModel { page, searchQuery, tag in
            requests.append((page, searchQuery, tag))
            return page == 2 ? tagSecondPage : tagFirstPage
        }

        viewModel.searchQuery = "rails"
        await viewModel.selectTag("hotwire_native")
        #expect(viewModel.searchQuery == "")
        #expect(viewModel.selectedTag == "hotwire_native")
        #expect(viewModel.articles.map(\.id) == ["tag-first-page"])
        #expect(viewModel.canLoadMore)

        await viewModel.loadMore()
        #expect(viewModel.articles.map(\.id) == ["tag-first-page", "tag-second-page"])
        #expect(!viewModel.canLoadMore)
        #expect(requests.map { $0.page } == [nil, 2])
        #expect(requests.map { $0.searchQuery } == [nil, nil])
        #expect(requests.map { $0.tag } == ["hotwire_native", "hotwire_native"])
    }

    @MainActor
    @Test func articlesResponseDecodesServerFeedShape() async throws {
        let json = """
        {
          "articles": [
            {
              "slug": "10-years-helping-rails-devs",
              "title": "10 years helping Rails devs",
              "title_ko": "Rails 개발자의 앱스토어 진출을 돕는 Ruby Native",
              "url": "https://masilotti.com/shipped-without-me/",
              "origin_url": "https://masilotti.com/shipped-without-me/",
              "host": "masilotti.com",
              "likers_count": 1,
              "posts_count": 0,
              "published_at": "2026-05-06T02:49:58.000+09:00",
              "summary_key": [
                "10년 넘게 Rails 개발자의 iOS 앱 출시를 도운 전문가가 Ruby Native를 출시했다."
              ],
              "tags": ["ruby_native", "hotwire_native", "ios"]
            }
          ],
          "pagination": {
            "page": 1,
            "next": 2,
            "limit": 15
          }
        }
        """

        let response = try APIClient.decoder.decode(ArticlesResponse.self, from: Data(json.utf8))
        let article = try #require(response.articles.first)

        #expect(article.id == "10-years-helping-rails-devs")
        #expect(article.displayTitle == "Rails 개발자의 앱스토어 진출을 돕는 Ruby Native")
        #expect(article.summary == "10년 넘게 Rails 개발자의 iOS 앱 출시를 도운 전문가가 Ruby Native를 출시했다.")
        #expect(article.host == "masilotti.com")
        #expect(article.likersCount == 1)
        #expect(article.postsCount == 0)
        #expect(article.tags == ["ruby_native", "hotwire_native", "ios"])
        #expect(article.detailURL(relativeTo: URL(string: "http://localhost:3000")!).absoluteString == "http://localhost:3000/articles/10-years-helping-rails-devs")
        #expect(response.pagination?.nextPage == 2)
    }

    @MainActor
    private func articlesResponse(slugs: [String], page: Int, next: Int?) throws -> ArticlesResponse {
        let articles = slugs.map { slug in
            """
            {
              "slug": "\(slug)",
              "title": "\(slug)",
              "url": "https://example.com/\(slug)",
              "host": "example.com",
              "likers_count": 0,
              "posts_count": 0,
              "summary_key": [],
              "tags": []
            }
            """
        }.joined(separator: ",")
        let nextValue = next.map(String.init) ?? "null"
        let json = """
        {
          "articles": [\(articles)],
          "pagination": {
            "page": \(page),
            "next": \(nextValue),
            "limit": 15
          }
        }
        """
        return try APIClient.decoder.decode(ArticlesResponse.self, from: Data(json.utf8))
    }
}
