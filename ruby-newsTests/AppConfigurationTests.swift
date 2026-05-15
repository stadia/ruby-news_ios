//
//  AppConfigurationTests.swift
//  ruby-newsTests
//

import Foundation
import Testing
@testable import ruby_news

@Suite(.serialized)
struct AppConfigurationTests {
    @Test func appTabsExposeInitialProductStructure() async throws {
        #expect(AppTab.allCases == [.news, .feed, .profile, .search])
        #expect(AppTab.news.title == "뉴스")
        #expect(AppTab.feed.title == "피드")
        #expect(AppTab.profile.title == "내 정보")
        #expect(AppTab.search.title == "검색")
    }

    @Test func appTabsExposeStableAccessibilityIdentifiers() async throws {
        #expect(AppTab.news.accessibilityIdentifier == "tab.news")
        #expect(AppTab.feed.accessibilityIdentifier == "tab.feed")
        #expect(AppTab.profile.accessibilityIdentifier == "tab.profile")
        #expect(AppTab.search.accessibilityIdentifier == "tab.search")
    }

    @Test func webRoutesBuildExpectedURLs() async throws {
        let baseURL = try #require(URL(string: "https://ruby-news.kr"))

        #expect(WebRoute.login.url(relativeTo: baseURL).absoluteString == "https://ruby-news.kr/login")
        #expect(WebRoute.feed.url(relativeTo: baseURL).absoluteString == "https://ruby-news.kr/feed")
        #expect(WebRoute.article(id: "rails-8-1").url(relativeTo: baseURL).absoluteString == "https://ruby-news.kr/articles/rails-8-1")
        #expect(WebRoute.profile(username: "matz").url(relativeTo: baseURL).absoluteString == "https://ruby-news.kr/@matz")
    }

    @Test func webRoutesPercentEncodeDynamicPathSegments() async throws {
        let baseURL = try #require(URL(string: "https://ruby-news.kr"))

        #expect(WebRoute.tag(keyword: "Ruby 뉴스").url(relativeTo: baseURL).absoluteString == "https://ruby-news.kr/tag/Ruby%20%EB%89%B4%EC%8A%A4")
        #expect(WebRoute.profile(username: "ruby_user").url(relativeTo: baseURL).absoluteString == "https://ruby-news.kr/@ruby_user")
    }

    @Test func articlesRequestUsesExistingEndpointWithJSONAcceptHeader() async throws {
        let baseURL = try #require(URL(string: "http://localhost:3000"))
        let request = APIRequest(path: "/articles").urlRequest(relativeTo: baseURL)

        #expect(request.url?.absoluteString == "http://localhost:3000/articles")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

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

    @Test func tagRequestEncodesKeywordPathAndCursorQuery() async throws {
        let baseURL = try #require(URL(string: "http://localhost:3000"))
        let cursor = "WyIyMDI2LTA1LTAzVDE5OjAzOjAwLjAwMCswOTowMCIsMTA5ODdd"
        let request = APIRequest.tag(keyword: "Ruby 뉴스", cursor: cursor).urlRequest(relativeTo: baseURL)

        #expect(request.url?.absoluteString == "http://localhost:3000/tag/Ruby%20%EB%89%B4%EC%8A%A4?page=WyIyMDI2LTA1LTAzVDE5OjAzOjAwLjAwMCswOTowMCIsMTA5ODdd")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

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
}
