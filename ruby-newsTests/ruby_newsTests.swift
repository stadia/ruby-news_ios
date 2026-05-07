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
    @Test func articlesRequestEncodesCursorQuery() async throws {
        let baseURL = try #require(URL(string: "http://localhost:3000"))
        let cursor = "WyIyMDI2LTA1LTAzVDE5OjAzOjAwLjAwMCswOTowMCIsMTA5ODdd"
        let request = APIRequest(
            path: "/articles",
            queryItems: [URLQueryItem(name: "page", value: cursor)]
        ).urlRequest(relativeTo: baseURL)

        #expect(request.url?.absoluteString == "http://localhost:3000/articles?page=WyIyMDI2LTA1LTAzVDE5OjAzOjAwLjAwMCswOTowMCIsMTA5ODdd")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @MainActor
    @Test func articlesRequestEncodesSearchAndCursorQuery() async throws {
        let baseURL = try #require(URL(string: "http://localhost:3000"))
        let cursor = "WyIyMDI2LTA1LTAzVDE5OjAzOjAwLjAwMCswOTowMCIsMTA5ODdd"
        let request = APIRequest(
            path: "/articles",
            queryItems: [
                URLQueryItem(name: "search", value: "rails hotwire"),
                URLQueryItem(name: "page", value: cursor)
            ]
        ).urlRequest(relativeTo: baseURL)

        #expect(request.url?.absoluteString == "http://localhost:3000/articles?search=rails%20hotwire&page=WyIyMDI2LTA1LTAzVDE5OjAzOjAwLjAwMCswOTowMCIsMTA5ODdd")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @MainActor
    @Test func tagRequestEncodesKeywordPathAndCursorQuery() async throws {
        let baseURL = try #require(URL(string: "http://localhost:3000"))
        let cursor = "WyIyMDI2LTA1LTAzVDE5OjAzOjAwLjAwMCswOTowMCIsMTA5ODdd"
        let request = APIRequest.tag(keyword: "Ruby 뉴스", cursor: cursor).urlRequest(relativeTo: baseURL)

        #expect(request.url?.absoluteString == "http://localhost:3000/tag/Ruby%20%EB%89%B4%EC%8A%A4?page=WyIyMDI2LTA1LTAzVDE5OjAzOjAwLjAwMCswOTowMCIsMTA5ODdd")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @MainActor
    @Test func newsViewModelAppendsNextPage() async throws {
        var requestedCursors: [String?] = []
        let firstCursor = "WyIyMDI2LTA1LTAzVDE5OjAzOjAwLjAwMCswOTowMCIsMTA5ODdd"
        let responses: [String: ArticlesResponse] = [
            "nil": try articlesResponse(slugs: ["first-page-article"], nextPage: firstCursor),
            firstCursor: try articlesResponse(slugs: ["second-page-article"], nextPage: nil)
        ]
        let viewModel = NewsViewModel { cursor, searchQuery, tag in
            #expect(searchQuery == nil)
            #expect(tag == nil)
            requestedCursors.append(cursor)
            let key = cursor ?? "nil"
            return try #require(responses[key])
        }

        await viewModel.load()
        #expect(viewModel.articles.map(\.id) == ["first-page-article"])
        #expect(viewModel.canLoadMore)

        await viewModel.loadMore()
        #expect(requestedCursors == [nil, firstCursor])
        #expect(viewModel.articles.map(\.id) == ["first-page-article", "second-page-article"])
        #expect(!viewModel.canLoadMore)
    }

    @MainActor
    @Test func newsViewModelSearchesAndPaginatesWithQuery() async throws {
        var requests: [(cursor: String?, searchQuery: String?, tag: String?)] = []
        let searchCursor = "WyIyMDI2LTA1LTAxVDEwOjAwOjU5LjE0NCswOTowMCIsMTA4MzJd"
        let defaultResponse = try articlesResponse(slugs: ["default-article"], nextPage: nil)
        let searchFirstPage = try articlesResponse(slugs: ["rails-first-page"], nextPage: searchCursor)
        let searchSecondPage = try articlesResponse(slugs: ["rails-second-page"], nextPage: nil)
        let viewModel = NewsViewModel { cursor, searchQuery, tag in
            requests.append((cursor, searchQuery, tag))

            if searchQuery == "rails" && cursor == nil {
                return searchFirstPage
            } else if searchQuery == "rails" && cursor == searchCursor {
                return searchSecondPage
            } else if searchQuery == nil && cursor == nil {
                return defaultResponse
            }

            Issue.record("Unexpected request cursor=\(String(describing: cursor)) search=\(String(describing: searchQuery))")
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
        #expect(requests.map { $0.cursor } == [nil, searchCursor, nil])
        #expect(requests.map { $0.searchQuery } == ["rails", "rails", nil])
        #expect(requests.map { $0.tag } == [nil, nil, nil])
    }

    @MainActor
    @Test func newsViewModelLoadMoreIfNeededTriggersWhenNearEnd() async throws {
        let nextPageCursor = "WyIyMDI2LTA1LTAzVDE5OjAzOjAwLjAwMCswOTowMCIsMTA5ODdd"
        let firstPage = try articlesResponse(slugs: (0..<20).map { "article-\($0)" }, nextPage: nextPageCursor)
        let secondPage = try articlesResponse(slugs: (0..<5).map { "page2-\($0)" }, nextPage: nil)
        var callCount = 0
        let viewModel = NewsViewModel { cursor, _, _ in
            callCount += 1
            return cursor == nil ? firstPage : secondPage
        }

        await viewModel.load()
        #expect(callCount == 1)
        #expect(viewModel.canLoadMore)

        // Articles near the end should trigger load more
        let lastArticle = try #require(viewModel.articles.last)
        await viewModel.loadMoreIfNeeded(current: lastArticle)
        #expect(callCount == 2)
        #expect(viewModel.articles.count == 25)
        #expect(!viewModel.canLoadMore)
    }

    @MainActor
    @Test func newsViewModelLoadMoreIfNeededSkipsWhenNotNearEnd() async throws {
        let nextPageCursor = "WyIyMDI2LTA1LTAzVDE5OjAzOjAwLjAwMCswOTowMCIsMTA5ODdd"
        let firstPage = try articlesResponse(slugs: (0..<20).map { "article-\($0)" }, nextPage: nextPageCursor)
        var callCount = 0
        let viewModel = NewsViewModel { _, _, _ in
            callCount += 1
            return firstPage
        }

        await viewModel.load()
        #expect(callCount == 1)

        // First article should NOT trigger load more
        let firstArticle = try #require(viewModel.articles.first)
        await viewModel.loadMoreIfNeeded(current: firstArticle)
        #expect(callCount == 1)
    }

    @MainActor
    @Test func newsViewModelLoadMoreIfNeededSkipsWhenNoMorePages() async throws {
        let singlePage = try articlesResponse(slugs: ["only-article"], nextPage: nil)
        let viewModel = NewsViewModel { _, _, _ in singlePage }

        await viewModel.load()
        #expect(!viewModel.canLoadMore)

        let article = try #require(viewModel.articles.first)
        await viewModel.loadMoreIfNeeded(current: article)
        // Should not make another request
        #expect(viewModel.articles.count == 1)
    }

    @MainActor
    @Test func newsViewModelFiltersAndPaginatesByTag() async throws {
        var requests: [(cursor: String?, searchQuery: String?, tag: String?)] = []
        let tagCursor = "WyIyMDI2LTA1LTAzVDE5OjAzOjAwLjAwMCswOTowMCIsMTA5ODdd"
        let tagFirstPage = try articlesResponse(slugs: ["tag-first-page"], nextPage: tagCursor)
        let tagSecondPage = try articlesResponse(slugs: ["tag-second-page"], nextPage: nil)
        let viewModel = NewsViewModel { cursor, searchQuery, tag in
            requests.append((cursor, searchQuery, tag))
            return cursor == nil ? tagFirstPage : tagSecondPage
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
        #expect(requests.map { $0.cursor } == [nil, tagCursor])
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
            "page": null,
            "next_page": "WyIyMDI2LTA1LTAzVDE5OjAzOjAwLjAwMCswOTowMCIsMTA5ODdd",
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
        #expect(response.pagination?.nextPage == "WyIyMDI2LTA1LTAzVDE5OjAzOjAwLjAwMCswOTowMCIsMTA5ODdd")
        #expect(response.pagination?.page == nil)
    }

    @MainActor
    @Test func articlesResponseDecodesLastPageWithNullNextPage() async throws {
        let json = """
        {
          "articles": [
            {
              "slug": "last-article",
              "title": "Last one",
              "url": "https://example.com/last",
              "likers_count": 0,
              "posts_count": 0,
              "summary_key": [],
              "tags": []
            }
          ],
          "pagination": {
            "page": "WyIyMDI2LTA1LTAxVDEwOjAwOjU5LjE0NCswOTowMCIsMTA4MzJd",
            "next_page": null,
            "limit": 15
          }
        }
        """

        let response = try APIClient.decoder.decode(ArticlesResponse.self, from: Data(json.utf8))
        #expect(response.pagination?.nextPage == nil)
        #expect(response.pagination?.page == "WyIyMDI2LTA1LTAxVDEwOjAwOjU5LjE0NCswOTowMCIsMTA4MzJd")
    }

    @MainActor
    private func articlesResponse(slugs: [String], nextPage: String?) throws -> ArticlesResponse {
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
        let nextValue = nextPage.map { "\"\($0)\"" } ?? "null"
        let json = """
        {
          "articles": [\(articles)],
          "pagination": {
            "page": null,
            "next": \(nextValue),
            "limit": 15
          }
        }
        """
        return try APIClient.decoder.decode(ArticlesResponse.self, from: Data(json.utf8))
    }

    // MARK: - CurrentUser Decoding

    @MainActor
    @Test func currentUserDecodesServerAccountResponse() async throws {
        let json = """
        {
          "user": {
            "id": 1,
            "email": "jeff@example.com",
            "name": "Jeff Dean",
            "username": "jeff",
            "avatar_url": "https://ruby-news.kr/rails/active_storage/blobs/redirect/abc123/avatar.jpeg"
          }
        }
        """

        let response = try APIClient.decoder.decode(AccountResponse.self, from: Data(json.utf8))
        let user = response.user

        #expect(user.id == 1)
        #expect(user.email == "jeff@example.com")
        #expect(user.name == "Jeff Dean")
        #expect(user.username == "jeff")
        #expect(user.avatarURL?.absoluteString == "https://ruby-news.kr/rails/active_storage/blobs/redirect/abc123/avatar.jpeg")
    }

    @MainActor
    @Test func currentUserDecodesWithoutAvatar() async throws {
        let json = """
        {
          "user": {
            "id": 2,
            "email": "noavatar@example.com",
            "name": "No Avatar",
            "username": "noavatar",
            "avatar_url": null
          }
        }
        """

        let response = try APIClient.decoder.decode(AccountResponse.self, from: Data(json.utf8))
        #expect(response.user.avatarURL == nil)
        #expect(response.user.username == "noavatar")
    }

    // MARK: - SessionStore

    @MainActor
    @Test func sessionStoreRefreshSetsCurrentUserOnSuccess() async throws {
        let sessionStore = SessionStore(fetchCurrentUser: {
            CurrentUser(id: 1, email: "jeff@example.com", name: "Jeff", username: "jeff", avatarURL: nil)
        })

        #expect(!sessionStore.isSignedIn)

        await sessionStore.refresh()
        #expect(sessionStore.isSignedIn)
        #expect(sessionStore.currentUser?.username == "jeff")
        #expect(!sessionStore.isLoading)
    }

    @MainActor
    @Test func sessionStoreRefreshClearsUserOnUnauthorized() async throws {
        let sessionStore = SessionStore(fetchCurrentUser: {
            throw APIError.unacceptableStatusCode(401)
        })

        await sessionStore.refresh()
        #expect(!sessionStore.isSignedIn)
        #expect(sessionStore.currentUser == nil)
        #expect(!sessionStore.isLoading)
    }

    @MainActor
    @Test func sessionStoreClearResetsUser() async {
        let sessionStore = SessionStore(fetchCurrentUser: {
            CurrentUser(id: 1, email: "jeff@example.com", name: "Jeff", username: "jeff", avatarURL: nil)
        })

        await sessionStore.refresh()
        #expect(sessionStore.isSignedIn)

        sessionStore.clear()
        #expect(!sessionStore.isSignedIn)
        #expect(sessionStore.currentUser == nil)
    }

    // MARK: - Article Like State

    @Test func newsArticleDecodesLikedState() async throws {
        let article = try makeArticle(slug: "liked-article", liked: true, likersCount: 10)

        #expect(article.liked)
        #expect(article.likersCount == 10)
    }

    @Test func newsArticleDefaultsLikedStateToFalseWhenMissing() async throws {
        let json = """
        {
          "slug": "article-without-liked",
          "title": "article-without-liked",
          "url": "https://example.com/article-without-liked",
          "host": "example.com",
          "likers_count": 3,
          "posts_count": 0,
          "summary_key": [],
          "tags": []
        }
        """

        let article = try APIClient.decoder.decode(NewsArticle.self, from: Data(json.utf8))
        #expect(!article.liked)
        #expect(article.likersCount == 3)
    }

    private func makeArticle(slug: String, liked: Bool, likersCount: Int) throws -> NewsArticle {
        let json = """
        {
          "slug": "\(slug)",
          "title": "\(slug)",
          "url": "https://example.com/\(slug)",
          "host": "example.com",
          "likers_count": \(likersCount),
          "liked": \(liked),
          "posts_count": 0,
          "summary_key": [],
          "tags": []
        }
        """
        return try APIClient.decoder.decode(NewsArticle.self, from: Data(json.utf8))
    }
}