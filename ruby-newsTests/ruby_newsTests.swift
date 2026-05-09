//
//  ruby_newsTests.swift
//  ruby-newsTests
//
//  Created by JEFF.DEAN on 5/6/26.
//

import Foundation
import Testing
@testable import ruby_news

@MainActor
@Suite(.serialized)
struct ruby_newsTests {

    @MainActor
    @Test func appTabsExposeInitialProductStructure() async throws {
        #expect(AppTab.allCases == [.news, .feed, .profile, .search])
        #expect(AppTab.news.title == "뉴스")
        #expect(AppTab.feed.title == "피드")
        #expect(AppTab.profile.title == "내 정보")
        #expect(AppTab.search.title == "검색")
    }

    @MainActor
    @Test func appTabsExposeStableAccessibilityIdentifiers() async throws {
        #expect(AppTab.news.accessibilityIdentifier == "tab.news")
        #expect(AppTab.feed.accessibilityIdentifier == "tab.feed")
        #expect(AppTab.profile.accessibilityIdentifier == "tab.profile")
        #expect(AppTab.search.accessibilityIdentifier == "tab.search")
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
        let viewModel = NewsViewModel(loadArticles: { _, cursor, searchQuery, tag in
            #expect(searchQuery == nil)
            #expect(tag == nil)
            requestedCursors.append(cursor)
            let key = cursor ?? "nil"
            return try #require(responses[key])
        })

        await viewModel.load()
        #expect(viewModel.articles.map { $0.id } == ["first-page-article"])
        #expect(viewModel.canLoadMore)

        await viewModel.loadMore()
        #expect(requestedCursors == [nil, firstCursor])
        #expect(viewModel.articles.map { $0.id } == ["first-page-article", "second-page-article"])
        #expect(!viewModel.canLoadMore)
    }

    @MainActor
    @Test func newsViewModelSearchesAndPaginatesWithQuery() async throws {
        var requests: [(cursor: String?, searchQuery: String?, tag: String?)] = []
        let searchCursor = "WyIyMDI2LTA1LTAxVDEwOjAwOjU5LjE0NCswOTowMCIsMTA4MzJd"
        let defaultResponse = try articlesResponse(slugs: ["default-article"], nextPage: nil)
        let searchFirstPage = try articlesResponse(slugs: ["rails-first-page"], nextPage: searchCursor)
        let searchSecondPage = try articlesResponse(slugs: ["rails-second-page"], nextPage: nil)
        let viewModel = NewsViewModel(loadArticles: { _, cursor, searchQuery, tag in
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
        })

        viewModel.searchQuery = "rails"
        await viewModel.search()
        #expect(viewModel.articles.map { $0.id } == ["rails-first-page"])
        #expect(viewModel.canLoadMore)

        await viewModel.loadMore()
        #expect(viewModel.articles.map { $0.id } == ["rails-first-page", "rails-second-page"])
        #expect(!viewModel.canLoadMore)

        viewModel.searchQuery = ""
        await viewModel.search()
        #expect(viewModel.articles.map { $0.id } == ["default-article"])
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
        let viewModel = NewsViewModel(loadArticles: { _, cursor, _, _ in
            callCount += 1
            return cursor == nil ? firstPage : secondPage
        })

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
        let viewModel = NewsViewModel(loadArticles: { _, _, _, _ in
            callCount += 1
            return firstPage
        })

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
        let viewModel = NewsViewModel(loadArticles: { _, _, _, _ in singlePage })

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
        let viewModel = NewsViewModel(loadArticles: { _, cursor, searchQuery, tag in
            requests.append((cursor, searchQuery, tag))
            return cursor == nil ? tagFirstPage : tagSecondPage
        })

        viewModel.searchQuery = "rails"
        await viewModel.selectTag("hotwire_native")
        #expect(viewModel.searchQuery == "")
        #expect(viewModel.selectedTag == "hotwire_native")
        #expect(viewModel.articles.map { $0.id } == ["tag-first-page"])
        #expect(viewModel.canLoadMore)

        await viewModel.loadMore()
        #expect(viewModel.articles.map { $0.id } == ["tag-first-page", "tag-second-page"])
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
        #expect(response.auth == nil)
    }

    @Test func accountResponseDecodesWithAuth() async throws {
        let json = """
        {
          "user": {
            "id": 1,
            "email": "jeff@example.com",
            "name": "Jeff",
            "username": "jeff",
            "avatar_url": null
          },
          "auth": {
            "access_token": "jwt-access",
            "refresh_token": "raw-refresh",
            "expires_in": 900
          }
        }
        """

        let response = try APIClient.decoder.decode(AccountResponse.self, from: Data(json.utf8))
        #expect(response.auth != nil)
        #expect(response.auth?.accessToken == "jwt-access")
        #expect(response.auth?.refreshToken == "raw-refresh")
        #expect(response.auth?.expiresIn == 900)

        let session = response.auth!.toAuthSession()
        #expect(session.accessToken == "jwt-access")
        #expect(session.refreshToken == "raw-refresh")
        #expect(!session.isExpired)
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
        let tokenStore = InMemoryTokenStore()
        try tokenStore.save(
            AuthSession(
                accessToken: "stale-access",
                refreshToken: "stale-refresh",
                expiresAt: Date().addingTimeInterval(900)
            )
        )
        let sessionStore = SessionStore(
            fetchCurrentUser: {
                throw APIError.unacceptableStatusCode(401)
            },
            tokenStore: tokenStore
        )
        sessionStore.restoreSession()

        await sessionStore.refresh()
        #expect(!sessionStore.isSignedIn)
        #expect(sessionStore.currentUser == nil)
        #expect(sessionStore.authSession == nil)
        #expect(try tokenStore.load() == nil)
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

    // MARK: - AuthSession

    @Test func authSessionParsesBearerHeader() async throws {
        let session = AuthSession(authorizationHeader: "Bearer eyJhbGciOiJIUzI1NiJ9.test")

        #expect(session != nil)
        #expect(session?.accessToken == "eyJhbGciOiJIUzI1NiJ9.test")
        #expect(session?.refreshToken == nil)
    }

    @Test func authSessionReturnsNilForMissingHeader() async {
        let session = AuthSession(authorizationHeader: nil)
        #expect(session == nil)
    }

    @Test func authSessionReturnsNilForNonBearerHeader() async {
        let session = AuthSession(authorizationHeader: "Basic abc123")
        #expect(session == nil)
    }

    @Test func authSessionReturnsNilForBearerWithEmptyToken() async {
        let session = AuthSession(authorizationHeader: "Bearer ")
        #expect(session == nil)
    }

    @Test func authSessionStoresRefreshToken() async throws {
        let session = AuthSession(
            authorizationHeader: "Bearer access-token",
            refreshToken: "raw-refresh-token"
        )

        #expect(session?.refreshToken == "raw-refresh-token")
    }

    @Test func authSessionCalculatesExpiresAt() async throws {
        let before = Date()
        let session = AuthSession(authorizationHeader: "Bearer token", expiresIn: 900)
        let after = Date()

        let expiresAt = try #require(session?.expiresAt)
        #expect(expiresAt >= before.addingTimeInterval(900))
        #expect(expiresAt <= after.addingTimeInterval(900))
    }

    @Test func authSessionDetectsExpiration() async throws {
        let expired = AuthSession(
            accessToken: "token",
            expiresAt: Date().addingTimeInterval(-1)
        )
        let valid = AuthSession(
            accessToken: "token",
            expiresAt: Date().addingTimeInterval(900)
        )

        #expect(expired.isExpired)
        #expect(!valid.isExpired)
    }

    @Test func refreshTokenResponseDecodes() async throws {
        let json = """
        {
          "access_token": "new-access",
          "refresh_token": "new-refresh",
          "expires_in": 900
        }
        """

        let response = try APIClient.decoder.decode(RefreshTokenResponse.self, from: Data(json.utf8))
        #expect(response.accessToken == "new-access")
        #expect(response.refreshToken == "new-refresh")
        #expect(response.expiresIn == 900)

        let session = response.toAuthSession()
        #expect(session.accessToken == "new-access")
        #expect(session.refreshToken == "new-refresh")
        #expect(!session.isExpired)
    }

    // MARK: - TokenStore

    @Test func inMemoryTokenStoreSavesAndLoads() async throws {
        let store = InMemoryTokenStore()
        #expect(try store.load() == nil)

        let session = AuthSession(
            accessToken: "access",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(900)
        )
        try store.save(session)

        let loaded = try #require(try store.load())
        #expect(loaded.accessToken == "access")
        #expect(loaded.refreshToken == "refresh")
    }

    @Test func inMemoryTokenStoreDeleteClearsSession() async throws {
        let store = InMemoryTokenStore()
        let session = AuthSession(
            accessToken: "access",
            expiresAt: Date().addingTimeInterval(900)
        )
        try store.save(session)
        #expect(try store.load() != nil)

        try store.delete()
        #expect(try store.load() == nil)
    }

    @Test func inMemoryTokenStoreSaveOverwritesPrevious() async throws {
        let store = InMemoryTokenStore()
        let first = AuthSession(
            accessToken: "first",
            expiresAt: Date().addingTimeInterval(900)
        )
        let second = AuthSession(
            accessToken: "second",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(900)
        )

        try store.save(first)
        try store.save(second)

        let loaded = try #require(try store.load())
        #expect(loaded.accessToken == "second")
        #expect(loaded.refreshToken == "refresh")
    }

    // MARK: - APIRequest Authorization

    @Test func apiRequestIncludesBearerTokenWhenProvided() async throws {
        let baseURL = try #require(URL(string: "http://localhost:3000"))
        let request = APIRequest(path: "/articles").urlRequest(
            relativeTo: baseURL,
            accessToken: "jwt-token-123"
        )

        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer jwt-token-123")
    }

    @Test func apiRequestOmitsAuthorizationWhenNoToken() async throws {
        let baseURL = try #require(URL(string: "http://localhost:3000"))
        let request = APIRequest(path: "/articles").urlRequest(relativeTo: baseURL)

        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    // MARK: - SessionStore AuthSession

    @MainActor
    @Test func sessionStoreSavesAndClearsAuthSession() async throws {
        let tokenStore = InMemoryTokenStore()
        let sessionStore = SessionStore(
            fetchCurrentUser: { throw APIError.unauthorized },
            tokenStore: tokenStore
        )

        let session = AuthSession(
            accessToken: "access",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(900)
        )

        sessionStore.save(authSession: session)
        #expect(sessionStore.authSession?.accessToken == "access")
        #expect(try tokenStore.load()?.accessToken == "access")

        sessionStore.clear()
        #expect(sessionStore.authSession == nil)
        #expect(sessionStore.currentUser == nil)
        #expect(try tokenStore.load() == nil)
    }

    @MainActor
    @Test func sessionStoreRestoresSessionFromTokenStore() async throws {
        let tokenStore = InMemoryTokenStore()
        let session = AuthSession(
            accessToken: "restored-access",
            refreshToken: "restored-refresh",
            expiresAt: Date().addingTimeInterval(900)
        )
        try tokenStore.save(session)

        let sessionStore = SessionStore(
            fetchCurrentUser: { throw APIError.unauthorized },
            tokenStore: tokenStore
        )

        #expect(sessionStore.authSession == nil)

        sessionStore.restoreSession()
        #expect(sessionStore.authSession?.accessToken == "restored-access")
        #expect(sessionStore.authSession?.refreshToken == "restored-refresh")
    }

    @MainActor
    @Test func sessionStoreLoginSetsUserAndAuth() async throws {
        let tokenStore = InMemoryTokenStore()
        let expectedUser = CurrentUser(id: 1, email: "jeff@example.com", name: "Jeff", username: "jeff", avatarURL: nil)
        let expectedAuth = AuthSession(
            accessToken: "native-access",
            refreshToken: "native-refresh",
            expiresAt: Date().addingTimeInterval(900)
        )

        let sessionStore = SessionStore(
            fetchAccount: { throw APIError.unauthorized },
            loginAction: { email, password in
                #expect(email == "jeff@example.com")
                #expect(password == "password")
                return APIClient.LoginResult(user: expectedUser, auth: expectedAuth)
            },
            tokenStore: tokenStore
        )

        try await sessionStore.login(email: "jeff@example.com", password: "password")

        #expect(sessionStore.isSignedIn)
        #expect(sessionStore.currentUser?.username == "jeff")
        #expect(sessionStore.authSession?.accessToken == "native-access")
        #expect(sessionStore.authSession?.refreshToken == "native-refresh")

        let stored = try #require(try tokenStore.load())
        #expect(stored.accessToken == "native-access")
        #expect(stored.refreshToken == "native-refresh")
    }

    @MainActor
    @Test func sessionStoreLoginLeavesStateUnchangedOnFailure() async throws {
        let tokenStore = InMemoryTokenStore()
        let sessionStore = SessionStore(
            fetchAccount: { throw APIError.unauthorized },
            loginAction: { _, _ in throw APIError.unacceptableStatusCode(401) },
            tokenStore: tokenStore
        )

        do {
            try await sessionStore.login(email: "wrong@example.com", password: "wrong")
            Issue.record("Expected login to throw")
        } catch APIError.unacceptableStatusCode(401) {
            // expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(!sessionStore.isSignedIn)
        #expect(sessionStore.authSession == nil)
        #expect(try tokenStore.load() == nil)
    }

    @MainActor
    @Test func sessionStoreLoginSyncsWebSessionAndBroadcastsChange() async throws {
        let tokenStore = InMemoryTokenStore()
        let expectedUser = CurrentUser(id: 1, email: "jeff@example.com", name: "Jeff", username: "jeff", avatarURL: nil)
        let expectedAuth = AuthSession(
            accessToken: "native-access",
            refreshToken: "native-refresh",
            expiresAt: Date().addingTimeInterval(900)
        )
        var didSyncWebSession = false
        var didNotifyWebSessionChange = false

        let sessionStore = SessionStore(
            fetchAccount: { throw APIError.unauthorized },
            loginAction: { _, _ in
                APIClient.LoginResult(user: expectedUser, auth: expectedAuth)
            },
            syncWebSession: {
                didSyncWebSession = true
            },
            notifyWebSessionChange: {
                didNotifyWebSessionChange = true
            },
            tokenStore: tokenStore
        )

        try await sessionStore.login(email: "jeff@example.com", password: "password")

        #expect(didSyncWebSession)
        #expect(didNotifyWebSessionChange)
    }

    @MainActor
    @Test func sessionStoreLogoutClearsLocalStateAfterSuccessfulRequest() async throws {
        let tokenStore = InMemoryTokenStore()
        let existingUser = CurrentUser(id: 1, email: "jeff@example.com", name: "Jeff", username: "jeff", avatarURL: nil)
        let existingAuth = AuthSession(accessToken: "jwt-token", refreshToken: "refresh", expiresAt: Date().addingTimeInterval(900))
        var logoutCalled = false

        let sessionStore = SessionStore(
            fetchAccount: { throw APIError.unauthorized },
            loginAction: { _, _ in throw APIError.unauthorized },
            logoutAction: {
                logoutCalled = true
            },
            tokenStore: tokenStore
        )
        sessionStore.currentUser = existingUser
        sessionStore.authSession = existingAuth
        try tokenStore.save(existingAuth)

        await sessionStore.logout()

        #expect(logoutCalled)
        #expect(sessionStore.currentUser == nil)
        #expect(sessionStore.authSession == nil)
        #expect(try tokenStore.load() == nil)
    }

    @MainActor
    @Test func sessionStoreLogoutClearsLocalStateEvenWhenRequestFails() async throws {
        let tokenStore = InMemoryTokenStore()
        let existingUser = CurrentUser(id: 1, email: "jeff@example.com", name: "Jeff", username: "jeff", avatarURL: nil)
        let existingAuth = AuthSession(accessToken: "jwt-token", refreshToken: "refresh", expiresAt: Date().addingTimeInterval(900))

        let sessionStore = SessionStore(
            fetchAccount: { throw APIError.unauthorized },
            loginAction: { _, _ in throw APIError.unauthorized },
            logoutAction: {
                throw APIError.unacceptableStatusCode(500)
            },
            tokenStore: tokenStore
        )
        sessionStore.currentUser = existingUser
        sessionStore.authSession = existingAuth
        try tokenStore.save(existingAuth)

        await sessionStore.logout()

        #expect(sessionStore.currentUser == nil)
        #expect(sessionStore.authSession == nil)
        #expect(try tokenStore.load() == nil)
    }

    @MainActor
    @Test func sessionStoreLogoutClearsWebSessionAndBroadcastsChangeEvenWhenRequestFails() async throws {
        let tokenStore = InMemoryTokenStore()
        let existingUser = CurrentUser(id: 1, email: "jeff@example.com", name: "Jeff", username: "jeff", avatarURL: nil)
        let existingAuth = AuthSession(accessToken: "jwt-token", refreshToken: "refresh", expiresAt: Date().addingTimeInterval(900))
        var didClearWebSession = false
        var didNotifyWebSessionChange = false

        let sessionStore = SessionStore(
            fetchAccount: { throw APIError.unauthorized },
            loginAction: { _, _ in throw APIError.unauthorized },
            logoutAction: {
                throw APIError.unacceptableStatusCode(500)
            },
            clearWebSession: {
                didClearWebSession = true
            },
            notifyWebSessionChange: {
                didNotifyWebSessionChange = true
            },
            tokenStore: tokenStore
        )
        sessionStore.currentUser = existingUser
        sessionStore.authSession = existingAuth
        try tokenStore.save(existingAuth)

        await sessionStore.logout()

        #expect(didClearWebSession)
        #expect(didNotifyWebSessionChange)
        #expect(sessionStore.currentUser == nil)
        #expect(sessionStore.authSession == nil)
    }

    @MainActor
    @Test func sessionStoreClearsStateWhenExternalSignOutIsHandled() async throws {
        let tokenStore = InMemoryTokenStore()
        let existingAuth = AuthSession(accessToken: "jwt-token", refreshToken: "refresh", expiresAt: Date().addingTimeInterval(900))
        let sessionStore = SessionStore(
            fetchAccount: { throw APIError.unauthorized },
            loginAction: { _, _ in throw APIError.unauthorized },
            tokenStore: tokenStore
        )
        sessionStore.currentUser = CurrentUser(id: 1, email: "jeff@example.com", name: "Jeff", username: "jeff", avatarURL: nil)
        sessionStore.authSession = existingAuth
        try tokenStore.save(existingAuth)

        var didClearWebSession = false
        var didNotifyWebSessionChange = false
        await SessionStore.handleExternalLogout(
            tokenStore: tokenStore,
            webSessionBridge: WebSessionBridge(
                loadCookies: { _ in [] },
                clearPersistedCookies: {},
                postChangeNotification: {
                    didNotifyWebSessionChange = true
                }
            ),
            clearWebSession: {
                didClearWebSession = true
            }
        )

        await Task.yield()

        #expect(didClearWebSession)
        #expect(didNotifyWebSessionChange)
        #expect(sessionStore.currentUser == nil)
        #expect(sessionStore.authSession == nil)
        #expect(try tokenStore.load() == nil)
    }

    // MARK: - APIClient.login

    @MainActor
    @Test func apIClientLoginDecodesResponse() async throws {
        let loginBody = """
        {
          "user": {
            "id": 1,
            "email": "jeff@example.com",
            "name": "Jeff",
            "username": "jeff",
            "avatar_url": null,
            "created_at": "2026-05-08T17:30:01.391+09:00",
            "updated_at": "2026-05-08T17:30:01.391+09:00"
          },
          "refresh_token": "raw-refresh-token"
        }
        """
        let loginURL = try #require(URL(string: "http://localhost:3000/login"))
        let mockResponse = HTTPURLResponse(url: loginURL, statusCode: 200, httpVersion: nil,
            headerFields: ["Content-Type": "application/json", "Authorization": "Bearer access-token"])!

        let session = URLSession.mockSession { request in
            #expect(request.url?.absoluteString == "http://localhost:3000/login")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            guard let body = requestBodyData(from: request),
                  let payload = try? JSONSerialization.jsonObject(with: body) as? [String: [String: String]] else {
                Issue.record("Expected JSON login request body")
                return (mockResponse, Data(loginBody.utf8))
            }
            #expect(payload["user"]?["email"] == "jeff@example.com")
            #expect(payload["user"]?["password"] == "password")

            return (mockResponse, Data(loginBody.utf8))
        }
        let client = APIClient(session: session)

        let result = try await client.login(email: "jeff@example.com", password: "password")
        let user = result.user
        let auth = result.auth

        #expect(user.id == 1)
        #expect(user.email == "jeff@example.com")
        #expect(user.name == "Jeff")
        #expect(user.username == "jeff")
        #expect(auth.accessToken == "access-token")
        #expect(auth.refreshToken == "raw-refresh-token")
    }

    @Test func apIClientLoginThrowsMissingAccessTokenWhenAuthorizationHeaderMissing() async {
        let session = URLSession.mockSession { request in
            (
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                Data("{\"user\":{\"id\":1,\"email\":\"jeff@example.com\",\"name\":\"Jeff\",\"username\":\"jeff\",\"avatar_url\":null},\"refresh_token\":\"refresh\"}".utf8)
            )
        }
        let client = APIClient(session: session)

        do {
            _ = try await client.login(email: "jeff@example.com", password: "password")
            Issue.record("Expected missing access token error")
        } catch APIError.missingAccessToken {
            // expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func apIClientLoginThrowsOn401() async {
        let session = URLSession.mockSession { request in
            (
                HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                Data("{\"error\":\"unauthorized\"}".utf8)
            )
        }
        let client = APIClient(session: session)

        do {
            _ = try await client.login(email: "wrong@example.com", password: "wrong")
            Issue.record("Expected login to throw")
        } catch APIError.unacceptableStatusCode(401) {
            // expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - APIClient Likes

    @MainActor
    @Test func apiClientLogoutUsesBearerTokenAndAcceptHeader() async throws {
        let auth = AuthSession(accessToken: "jwt-token", refreshToken: "refresh", expiresAt: Date().addingTimeInterval(900))
        let session = URLSession.mockSession { request in
            #expect(request.url?.absoluteString == "http://localhost:3000/logout")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer jwt-token")
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
            return (
                HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                nil
            )
        }
        let client = APIClient(session: session, tokenProvider: { auth })

        try await client.logout()
    }

    @Test func webSessionBridgeCopiesSharedCookiesIntoWebViewStore() async throws {
        let baseURL = try #require(URL(string: "http://localhost:3000"))
        let sessionCookie = try makeCookie(name: "_al_news_session", value: "cookie-value", domain: "localhost")
        var copiedCookies: [HTTPCookie] = []
        var persistedCookies: [PersistedWebSessionCookie] = []

        let bridge = WebSessionBridge(
            baseURL: baseURL,
            loadCookies: { url in
                #expect(url == baseURL)
                return [sessionCookie]
            },
            setCookie: { cookie in
                copiedCookies.append(cookie)
            },
            savePersistedCookies: { cookies in
                persistedCookies = cookies
            }
        )

        await bridge.syncSharedCookiesToWebView()

        #expect(copiedCookies.map(\.name) == ["_al_news_session"])
        #expect(persistedCookies.map(\.name) == ["_al_news_session"])
        #expect(persistedCookies.map(\.value) == ["cookie-value"])
    }

    @Test func webSessionBridgeRestoresPersistedCookiesIntoSharedStorage() async throws {
        let baseURL = try #require(URL(string: "http://localhost:3000"))
        let persistedCookie = PersistedWebSessionCookie(
            name: "_al_news_session",
            value: "cookie-value",
            domain: "localhost",
            path: "/",
            isSecure: false,
            expiresDate: nil
        )
        var restoredCookies: [HTTPCookie] = []

        let bridge = WebSessionBridge(
            baseURL: baseURL,
            loadCookies: { _ in [] },
            storeSharedCookie: { cookie, url in
                #expect(url == baseURL)
                restoredCookies.append(cookie)
            },
            loadPersistedCookies: { [persistedCookie] }
        )

        bridge.restorePersistedCookiesToSharedStorage()

        #expect(restoredCookies.map(\.name) == ["_al_news_session"])
        #expect(restoredCookies.map(\.value) == ["cookie-value"])
    }

    @Test func webAuthEventMonitorTriggersExternalLogoutWhenProtectedWebSessionIsGone() async throws {
        let logoutCount = LockedBox(0)
        let monitor = WebAuthEventMonitor(
            hasNativeAuthSession: { true },
            isProtectedURL: { _ in true },
            webSessionIsAuthenticated: { false },
            handleExternalLogout: {
                logoutCount.value += 1
            }
        )

        monitor.requestDidFinish(at: try #require(URL(string: "https://ruby-news.kr/feed")))
        await Task.yield()

        #expect(logoutCount.value == 1)
    }

    @Test func webAuthEventMonitorSkipsSessionCheckWithoutNativeAuth() async throws {
        let logoutCount = LockedBox(0)
        let monitor = WebAuthEventMonitor(
            hasNativeAuthSession: { false },
            isProtectedURL: { _ in true },
            webSessionIsAuthenticated: {
                Issue.record("Should not check web session without native auth")
                return false
            },
            handleExternalLogout: {
                logoutCount.value += 1
            }
        )

        monitor.requestDidFinish(at: try #require(URL(string: "https://ruby-news.kr/feed")))
        await Task.yield()

        #expect(logoutCount.value == 0)
    }

    @Test func webAuthEventMonitorSkipsPublicURLs() async throws {
        let logoutCount = LockedBox(0)
        let monitor = WebAuthEventMonitor(
            hasNativeAuthSession: { true },
            isProtectedURL: { _ in false },
            webSessionIsAuthenticated: {
                Issue.record("Should not check public URLs")
                return false
            },
            handleExternalLogout: {
                logoutCount.value += 1
            }
        )

        monitor.requestDidFinish(at: try #require(URL(string: "https://ruby-news.kr/@jeff")))
        await Task.yield()

        #expect(logoutCount.value == 0)
    }

    @Test func webSessionBridgeClearsSharedWebAndPersistedCookies() async throws {
        let baseURL = try #require(URL(string: "http://localhost:3000"))
        let sessionCookie = try makeCookie(name: "_al_news_session", value: "cookie-value", domain: "localhost")
        var deletedWebCookies: [HTTPCookie] = []
        var deletedSharedCookies: [HTTPCookie] = []
        var didClearPersistedCookies = false

        let bridge = WebSessionBridge(
            baseURL: baseURL,
            loadCookies: { _ in [sessionCookie] },
            deleteSharedCookie: { cookie in
                deletedSharedCookies.append(cookie)
            },
            deleteCookie: { cookie in
                deletedWebCookies.append(cookie)
            },
            clearPersistedCookies: {
                didClearPersistedCookies = true
            }
        )

        await bridge.clearCookies()

        #expect(deletedSharedCookies.map(\.name) == ["_al_news_session"])
        #expect(deletedWebCookies.map(\.name) == ["_al_news_session"])
        #expect(didClearPersistedCookies)
    }

    @Test func apiClientLikeRefreshesTokenAndRetriesAfterUnauthorized() async throws {
        let staleAuth = AuthSession(accessToken: "stale-access", refreshToken: "refresh-token", expiresAt: Date().addingTimeInterval(-60))
        let refreshedAuth = AuthSession(accessToken: "fresh-access", refreshToken: "fresh-refresh", expiresAt: Date().addingTimeInterval(900))
        let authBox = LockedBox(staleAuth)
        let didPersistRefreshedToken = LockedBox(false)
        var recordedAuthHeaders: [String?] = []

        let session = URLSession.mockSession { request in
            let path = request.url?.path

            switch path {
            case "/articles/rails-8-1/like":
                recordedAuthHeaders.append(request.value(forHTTPHeaderField: "Authorization"))
                let statusCode = recordedAuthHeaders.count == 1 ? 401 : 201
                let body = recordedAuthHeaders.count == 1
                    ? Data("{\"error\":\"unauthorized\"}".utf8)
                    : Data("{\"likeable_type\":\"Article\",\"likeable_slug\":\"rails-8-1\",\"liked\":true,\"likes_count\":13}".utf8)
                return (
                    HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                    body
                )
            case "/api/v1/auth/refresh":
                #expect(request.httpMethod == "POST")
                #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
                #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

                guard let body = requestBodyData(from: request),
                      let payload = try? JSONSerialization.jsonObject(with: body) as? [String: String] else {
                    Issue.record("Expected refresh request body")
                    return (
                        HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                        Data("{\"access_token\":\"fresh-access\",\"refresh_token\":\"fresh-refresh\",\"expires_in\":900}".utf8)
                    )
                }
                #expect(payload["refresh_token"] == "refresh-token")

                return (
                    HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                    Data("{\"access_token\":\"fresh-access\",\"refresh_token\":\"fresh-refresh\",\"expires_in\":900}".utf8)
                )
            default:
                Issue.record("Unexpected path: \(path ?? "nil")")
                return (
                    HTTPURLResponse(url: request.url ?? URL(string: "http://localhost:3000")!, statusCode: 404, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                    nil
                )
            }
        }

        var client = APIClient(session: session, tokenProvider: { authBox.value })
        client.onTokenRefreshed = { session in
            authBox.value = session
            didPersistRefreshedToken.value = true
        }

        let response = try await client.like(articleSlug: "rails-8-1")

        #expect(response.liked)
        #expect(response.likesCount == 13)
        #expect(recordedAuthHeaders == ["Bearer stale-access", "Bearer fresh-access"])
        #expect(didPersistRefreshedToken.value)
        #expect(authBox.value.accessToken == refreshedAuth.accessToken)
        #expect(authBox.value.refreshToken == refreshedAuth.refreshToken)
    }

    @MainActor
    @Test func sessionStoreRefreshUpdatesAuthSessionAfterTokenRefreshRetry() async throws {
        let tokenStore = InMemoryTokenStore()
        let staleAuth = AuthSession(accessToken: "stale-access", refreshToken: "refresh-token", expiresAt: Date().addingTimeInterval(-60))
        try tokenStore.save(staleAuth)

        var meRequestCount = 0
        let session = URLSession.mockSession { request in
            let path = request.url?.path

            switch path {
            case "/account/edit":
                meRequestCount += 1
                let statusCode = meRequestCount == 1 ? 401 : 200
                let body = meRequestCount == 1
                    ? Data("{\"error\":\"unauthorized\"}".utf8)
                    : Data("{\"user\":{\"id\":1,\"email\":\"jeff@example.com\",\"name\":\"Jeff\",\"username\":\"jeff\",\"avatar_url\":null}}".utf8)
                let expectedAuth = meRequestCount == 1 ? "Bearer stale-access" : "Bearer fresh-access"
                #expect(request.value(forHTTPHeaderField: "Authorization") == expectedAuth)
                return (
                    HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                    body
                )
            case "/api/v1/auth/refresh":
                guard let body = requestBodyData(from: request),
                      let payload = try? JSONSerialization.jsonObject(with: body) as? [String: String] else {
                    Issue.record("Expected refresh request body")
                    return (
                        HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                        Data("{\"access_token\":\"fresh-access\",\"refresh_token\":\"fresh-refresh\",\"expires_in\":900}".utf8)
                    )
                }
                #expect(payload["refresh_token"] == "refresh-token")
                return (
                    HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                    Data("{\"access_token\":\"fresh-access\",\"refresh_token\":\"fresh-refresh\",\"expires_in\":900}".utf8)
                )
            default:
                Issue.record("Unexpected path: \(path ?? "nil")")
                return (
                    HTTPURLResponse(url: request.url ?? URL(string: "http://localhost:3000")!, statusCode: 404, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                    nil
                )
            }
        }

        let client = APIClient(baseURL: URL(string: "http://localhost:3000")!, session: session)
        let sessionStore = SessionStore(apiClient: client, tokenStore: tokenStore)
        sessionStore.restoreSession()

        await sessionStore.refresh()

        #expect(sessionStore.currentUser?.username == "jeff")
        #expect(sessionStore.authSession?.accessToken == "fresh-access")
        #expect(sessionStore.authSession?.refreshToken == "fresh-refresh")
        #expect(try tokenStore.load()?.accessToken == "fresh-access")
        #expect(try tokenStore.load()?.refreshToken == "fresh-refresh")
    }

    @MainActor
    @Test func apiClientLikeSendsBearerTokenAndDecodesResponse() async throws {
        let auth = AuthSession(accessToken: "jwt-token", refreshToken: "refresh", expiresAt: Date().addingTimeInterval(900))
        let responseBody = """
        {
          "likeable_type": "Article",
          "likeable_slug": "rails-8-1",
          "liked": true,
          "likes_count": 13
        }
        """
        let session = URLSession.mockSession { request in
            #expect(request.url?.absoluteString == "http://localhost:3000/articles/rails-8-1/like")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer jwt-token")
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            guard let body = requestBodyData(from: request),
                  let payload = try? JSONSerialization.jsonObject(with: body) as? [String: String] else {
                Issue.record("Expected JSON like request body")
                return (
                    HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                    Data(responseBody.utf8)
                )
            }
            #expect(payload["likeable_type"] == "Article")

            return (
                HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                Data(responseBody.utf8)
            )
        }
        let client = APIClient(session: session, tokenProvider: { auth })

        let response = try await client.like(articleSlug: "rails-8-1")
        let liked = response.liked
        let likesCount = response.likesCount
        let likeableSlug = response.likeableSlug
        #expect(liked)
        #expect(likesCount == 13)
        #expect(likeableSlug == "rails-8-1")
    }

    @MainActor
    @Test func apiClientUnlikeSendsDeleteAndDecodesResponse() async throws {
        let auth = AuthSession(accessToken: "jwt-token", refreshToken: "refresh", expiresAt: Date().addingTimeInterval(900))
        let responseBody = """
        {
          "likeable_type": "Article",
          "likeable_slug": "rails-8-1",
          "liked": false,
          "likes_count": 12
        }
        """
        let session = URLSession.mockSession { request in
            #expect(request.url?.absoluteString == "http://localhost:3000/articles/rails-8-1/like")
            #expect(request.httpMethod == "DELETE")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer jwt-token")
            return (
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                Data(responseBody.utf8)
            )
        }
        let client = APIClient(session: session, tokenProvider: { auth })

        let response = try await client.unlike(articleSlug: "rails-8-1")
        let liked = response.liked
        let likesCount = response.likesCount
        #expect(!liked)
        #expect(likesCount == 12)
    }

    // MARK: - NewsViewModel Source

    @MainActor
    @Test func newsViewModelDefaultSourceIsRuby() async {
        let viewModel = NewsViewModel(loadArticles: { _, _, _, _ in ArticlesResponse(articles: [], pagination: nil) })
        #expect(viewModel.source == .ruby)
    }

    @MainActor
    @Test func newsViewModelSelectSourceLoadsFromCorrectEndpoint() async throws {
        var loadedSources: [NewsSource] = []
        let viewModel = NewsViewModel(loadArticles: { source, _, _, _ in
            loadedSources.append(source)
            return ArticlesResponse(articles: [], pagination: nil)
        })

        await viewModel.load()
        await viewModel.selectSource(.others)

        #expect(loadedSources == [.ruby, .others])
        #expect(viewModel.source == .others)
    }

    @MainActor
    @Test func newsViewModelSelectSourceClearsTagAndSearch() async throws {
        let viewModel = NewsViewModel(loadArticles: { _, _, _, _ in ArticlesResponse(articles: [], pagination: nil) })

        await viewModel.selectTag("rails")
        viewModel.searchQuery = "hotwire"
        await viewModel.selectSource(.others)

        #expect(viewModel.selectedTag == nil)
        #expect(viewModel.searchQuery == "")
        #expect(viewModel.source == .others)
    }

    // MARK: - NewsViewModel Likes

    @MainActor
    @Test func newsViewModelToggleLikeUpdatesArticleOnSuccess() async throws {
        let article = try makeArticle(slug: "rails-8-1", liked: false, likersCount: 12)
        let viewModel = NewsViewModel(
            loadArticles: { (_: NewsSource, _: String?, _: String?, _: String?) async throws -> ArticlesResponse in
                ArticlesResponse(articles: [article], pagination: nil)
            },
            toggleLike: { (toggledArticle: NewsArticle) async throws -> LikeResponse in
                #expect(toggledArticle.slug == "rails-8-1")
                return LikeResponse(likeableType: "Article", likeableSlug: "rails-8-1", liked: true, likesCount: 13)
            }
        )

        await viewModel.load()
        let current = try #require(viewModel.articles.first)
        await viewModel.toggleLike(current)

        let updatedArticle = try #require(viewModel.articles.first)
        let errorMessage = viewModel.errorMessage
        #expect(updatedArticle.liked == true)
        #expect(updatedArticle.likersCount == 13)
        #expect(errorMessage == nil)
    }

    @MainActor
    @Test func newsViewModelToggleLikeRollsBackAndShowsUnauthorizedError() async throws {
        let article = try makeArticle(slug: "rails-8-1", liked: false, likersCount: 12)
        let viewModel = NewsViewModel(
            loadArticles: { (_: NewsSource, _: String?, _: String?, _: String?) async throws -> ArticlesResponse in
                ArticlesResponse(articles: [article], pagination: nil)
            },
            toggleLike: { (_: NewsArticle) async throws -> LikeResponse in
                throw APIError.unauthorized
            }
        )

        await viewModel.load()
        let current = try #require(viewModel.articles.first)
        await viewModel.toggleLike(current)

        let updatedArticle = try #require(viewModel.articles.first)
        let errorMessage = viewModel.errorMessage
        #expect(updatedArticle.liked == false)
        #expect(updatedArticle.likersCount == 12)
        #expect(errorMessage == "로그인이 필요합니다.")
    }

    private func makeCookie(name: String, value: String, domain: String, path: String = "/") throws -> HTTPCookie {
        let properties: [HTTPCookiePropertyKey: Any] = [
            .name: name,
            .value: value,
            .domain: domain,
            .path: path,
            .secure: "FALSE"
        ]
        return try #require(HTTPCookie(properties: properties))
    }

    private func requestBodyData(from request: URLRequest) -> Data? {
        if let body = request.httpBody {
            return body
        }

        guard let stream = request.httpBodyStream else {
            return nil
        }

        stream.open()
        defer { stream.close() }

        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        var data = Data()
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            guard read > 0 else { break }
            data.append(buffer, count: read)
        }

        return data.isEmpty ? nil : data
    }
}

private final class LockedBox<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: Value

    init(_ value: Value) {
        storage = value
    }

    var value: Value {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storage
        }
        set {
            lock.lock()
            storage = newValue
            lock.unlock()
        }
    }
}