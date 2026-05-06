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
}
