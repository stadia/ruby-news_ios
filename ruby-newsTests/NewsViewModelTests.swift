//
//  NewsViewModelTests.swift
//  ruby-newsTests
//

import Foundation
import Testing
@testable import ruby_news

@MainActor
@Suite(.serialized)
struct NewsViewModelTests {
    @Test func newsViewModelAppendsNextPage() async throws {
        var requestedCursors: [String?] = []
        let firstCursor = "WyIyMDI2LTA1LTAzVDE5OjAzOjAwLjAwMCswOTowMCIsMTA5ODdd"
        let responses: [String: ArticlesResponse] = [
            "nil": try TestHelpers.articlesResponse(slugs: ["first-page-article"], nextPage: firstCursor),
            firstCursor: try TestHelpers.articlesResponse(slugs: ["second-page-article"], nextPage: nil)
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

    @Test func newsViewModelSearchesAndPaginatesWithQuery() async throws {
        var requests: [(cursor: String?, searchQuery: String?, tag: String?)] = []
        let searchCursor = "WyIyMDI2LTA1LTAxVDEwOjAwOjU5LjE0NCswOTowMCIsMTA4MzJd"
        let defaultResponse = try TestHelpers.articlesResponse(slugs: ["default-article"], nextPage: nil)
        let searchFirstPage = try TestHelpers.articlesResponse(slugs: ["rails-first-page"], nextPage: searchCursor)
        let searchSecondPage = try TestHelpers.articlesResponse(slugs: ["rails-second-page"], nextPage: nil)
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

    @Test func newsViewModelLoadMoreIfNeededTriggersWhenNearEnd() async throws {
        let nextPageCursor = "WyIyMDI2LTA1LTAzVDE5OjAzOjAwLjAwMCswOTowMCIsMTA5ODdd"
        let firstPage = try TestHelpers.articlesResponse(slugs: (0..<20).map { "article-\($0)" }, nextPage: nextPageCursor)
        let secondPage = try TestHelpers.articlesResponse(slugs: (0..<5).map { "page2-\($0)" }, nextPage: nil)
        var callCount = 0
        let viewModel = NewsViewModel(loadArticles: { _, cursor, _, _ in
            callCount += 1
            return cursor == nil ? firstPage : secondPage
        })

        await viewModel.load()
        #expect(callCount == 1)
        #expect(viewModel.canLoadMore)

        let lastArticle = try #require(viewModel.articles.last)
        await viewModel.loadMoreIfNeeded(current: lastArticle)
        #expect(callCount == 2)
        #expect(viewModel.articles.count == 25)
        #expect(!viewModel.canLoadMore)
    }

    @Test func newsViewModelLoadMoreIfNeededSkipsWhenNotNearEnd() async throws {
        let nextPageCursor = "WyIyMDI2LTA1LTAzVDE5OjAzOjAwLjAwMCswOTowMCIsMTA5ODdd"
        let firstPage = try TestHelpers.articlesResponse(slugs: (0..<20).map { "article-\($0)" }, nextPage: nextPageCursor)
        var callCount = 0
        let viewModel = NewsViewModel(loadArticles: { _, _, _, _ in
            callCount += 1
            return firstPage
        })

        await viewModel.load()
        #expect(callCount == 1)

        let firstArticle = try #require(viewModel.articles.first)
        await viewModel.loadMoreIfNeeded(current: firstArticle)
        #expect(callCount == 1)
    }

    @Test func newsViewModelLoadMoreIfNeededSkipsWhenNoMorePages() async throws {
        let singlePage = try TestHelpers.articlesResponse(slugs: ["only-article"], nextPage: nil)
        let viewModel = NewsViewModel(loadArticles: { _, _, _, _ in singlePage })

        await viewModel.load()
        #expect(!viewModel.canLoadMore)

        let article = try #require(viewModel.articles.first)
        await viewModel.loadMoreIfNeeded(current: article)
        #expect(viewModel.articles.count == 1)
    }

    @Test func newsViewModelFiltersAndPaginatesByTag() async throws {
        var requests: [(cursor: String?, searchQuery: String?, tag: String?)] = []
        let tagCursor = "WyIyMDI2LTA1LTAzVDE5OjAzOjAwLjAwMCswOTowMCIsMTA5ODdd"
        let tagFirstPage = try TestHelpers.articlesResponse(slugs: ["tag-first-page"], nextPage: tagCursor)
        let tagSecondPage = try TestHelpers.articlesResponse(slugs: ["tag-second-page"], nextPage: nil)
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

    @Test func newsViewModelDefaultSourceIsRuby() async {
        let viewModel = NewsViewModel(loadArticles: { _, _, _, _ in ArticlesResponse(articles: [], pagination: nil) })
        #expect(viewModel.source == .ruby)
    }

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

    @Test func newsViewModelSelectSourceClearsTagAndSearch() async throws {
        let viewModel = NewsViewModel(loadArticles: { _, _, _, _ in ArticlesResponse(articles: [], pagination: nil) })

        await viewModel.selectTag("rails")
        viewModel.searchQuery = "hotwire"
        await viewModel.selectSource(.others)

        #expect(viewModel.selectedTag == nil)
        #expect(viewModel.searchQuery == "")
        #expect(viewModel.source == .others)
    }

    @Test func newsViewModelToggleLikeUpdatesArticleOnSuccess() async throws {
        let article = try TestHelpers.makeArticle(slug: "rails-8-1", liked: false, likersCount: 12)
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
        #expect(updatedArticle.liked == true)
        #expect(updatedArticle.likersCount == 13)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func newsViewModelToggleLikeRollsBackAndShowsUnauthorizedError() async throws {
        let article = try TestHelpers.makeArticle(slug: "rails-8-1", liked: false, likersCount: 12)
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
        #expect(updatedArticle.liked == false)
        #expect(updatedArticle.likersCount == 12)
        #expect(viewModel.errorMessage == "로그인이 필요합니다.")
    }
}
