//
//  NewsArticleTests.swift
//  ruby-newsTests
//

import Foundation
import Testing
@testable import ruby_news

@Suite(.serialized)
struct NewsArticleTests {
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

    @Test func newsArticleDecodesLikedState() async throws {
        let article = try TestHelpers.makeArticle(slug: "liked-article", liked: true, likersCount: 10)

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
}
