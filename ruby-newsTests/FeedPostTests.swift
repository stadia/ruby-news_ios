import Foundation
import SwiftUI
import Testing
@testable import ruby_news

@MainActor
struct FeedPostTests {
    @Test
    func feedResponseDecodesDocumentedServerShape() throws {
        let json = """
        {
          "posts": [
            {
              "id": 42,
              "slug": "native-feed-post",
              "body": "Native Feed가 시작됩니다.",
              "post_type": "short",
              "status": "published",
              "created_at": "2026-06-13T09:30:00.123+09:00",
              "updated_at": "2026-06-13T09:31:00.123+09:00",
              "likes_count": 3,
              "boosts_count": 2,
              "liked": true,
              "boosted": false,
              "author_name": "Jeff",
              "author_host": "(ruby.social)",
              "article_slug": "rails-8-1",
              "parent_slug": "parent-post",
              "boosted_by": "alice"
            }
          ],
          "pagination": {
            "next_page": 2,
            "limit": 20
          }
        }
        """

        let response = try APIClient.decoder.decode(FeedResponse.self, from: Data(json.utf8))
        let post = try #require(response.posts.first)

        #expect(post.id == 42)
        #expect(post.slug == "native-feed-post")
        #expect(post.body == "Native Feed가 시작됩니다.")
        #expect(post.postType == .short)
        #expect(post.status == "published")
        #expect(post.createdAt != nil)
        #expect(post.updatedAt != nil)
        #expect(post.likesCount == 3)
        #expect(post.boostsCount == 2)
        #expect(post.liked)
        #expect(!post.boosted)
        #expect(post.authorName == "Jeff")
        #expect(post.authorHost == "(ruby.social)")
        #expect(post.articleSlug == "rails-8-1")
        #expect(post.parentSlug == "parent-post")
        #expect(post.boostedBy == "alice")
        #expect(response.pagination.nextPage == "2")
        #expect(response.pagination.limit == 20)
    }

    @Test
    func feedResponseDecodesRubyTimeDateFormat() throws {
        // 서버의 Alba/Oj serialization이 반환하는 Ruby Time 형식 검증.
        let json = """
        {
          "id": 5,
          "slug": "ruby-format-post",
          "body": "Ruby Time 테스트",
          "post_type": "blog",
          "status": "published",
          "created_at": "2026-03-21 16:40:35 +0900",
          "updated_at": "2026-03-21 16:40:39 +0900",
          "likes_count": 0,
          "boosts_count": 0,
          "liked": false,
          "boosted": false
        }
        """

        let post = try APIClient.decoder.decode(FeedPost.self, from: Data(json.utf8))

        #expect(post.id == 5)
        #expect(post.slug == "ruby-format-post")
        #expect(post.postType == .blog)
        #expect(post.createdAt != nil)
        #expect(post.updatedAt != nil)
    }

    @Test
    func paginationNextPageConvertsIntegerToString() throws {
        let json = """
        {
          "next_page": 2,
          "limit": 20
        }
        """

        let pagination = try APIClient.decoder.decode(FeedPagination.self, from: Data(json.utf8))

        #expect(pagination.nextPage == "2")
        #expect(pagination.limit == 20)
    }

    @Test
    func paginationNextPageHandlesNull() throws {
        let json = """
        {
          "next_page": null,
          "limit": 20
        }
        """

        let pagination = try APIClient.decoder.decode(FeedPagination.self, from: Data(json.utf8))

        #expect(pagination.nextPage == nil)
        #expect(pagination.limit == 20)
    }

    @Test
    func displayBodyStripsHTMLTagsToPlainText() throws {
        let post = try makePost(body: "<p>Hello <strong>world</strong></p>")

        #expect(post.displayBody == "Hello world")
    }

    @Test
    func displayBodyJoinsBlockElementsWithNewlines() throws {
        let post = try makePost(body: "<p>첫째 줄</p><p>둘째 줄</p>")

        #expect(post.displayBody == "첫째 줄\n둘째 줄")
    }

    @Test
    func displayBodyDecodesCommonHTMLEntities() throws {
        let post = try makePost(body: "<p>a &amp; b &lt; c &gt; d &quot;e&quot; &#39;f&#39; &nbsp;g</p>")

        #expect(post.displayBody == "a & b < c > d \"e\" 'f' \u{00a0}g")
    }

    @Test
    func displayBodyPassesPlainTextThrough() throws {
        let post = try makePost(body: "그냥 평문입니다.")

        #expect(post.displayBody == "그냥 평문입니다.")
    }

    @Test
    func linksExtractAnchorHrefAndTextInOrder() throws {
        let post = try makePost(
            body: "<p><a href=\"https://a.com\">A</a> 그리고 <a href='https://b.com'>B</a></p>"
        )

        #expect(post.links == [
            FeedLink(text: "A", url: try #require(URL(string: "https://a.com"))),
            FeedLink(text: "B", url: try #require(URL(string: "https://b.com")))
        ])
    }

    @Test
    func linksIgnoreEmptyHrefAndMissingHref() throws {
        let post = try makePost(body: "<p><a href=\"\">x</a> <a>y</a> 평문</p>")

        #expect(post.links.isEmpty)
    }

    @Test
    func linksDecodeEntitiesInAnchorText() throws {
        let post = try makePost(body: "<p><a href=\"https://x.com\">a &amp; b</a></p>")

        #expect(post.links == [
            FeedLink(text: "a & b", url: try #require(URL(string: "https://x.com")))
        ])
    }

    @Test
    func linksHandleAttributesAfterHref() throws {
        let post = try makePost(
            body: "<p><a href=\"https://x.com\" target=\"_blank\" rel=\"noopener\">열기</a></p>"
        )

        #expect(post.links == [
            FeedLink(text: "열기", url: try #require(URL(string: "https://x.com")))
        ])
    }

    @Test
    func linksStripNestedTagsInAnchorText() throws {
        let post = try makePost(
            body: "<p><a href=\"https://x.com\"><strong>굵게</strong></a></p>"
        )

        #expect(post.links == [
            FeedLink(text: "굵게", url: try #require(URL(string: "https://x.com")))
        ])
    }

    @Test
    func displayBodyStillKeepsAnchorInnerText() throws {
        let post = try makePost(body: "<p>보세요 <a href=\"https://x.com\">여기</a> 클릭</p>")

        #expect(post.displayBody == "보세요 여기 클릭")
    }

    @Test
    func attributedBodyMarksAnchorTextAsLink() throws {
        let post = try makePost(
            body: "<p>보세요 <a href=\"https://example.com\">여기</a> 클릭</p>"
        )

        let attributed = FeedPostRow.attributedBody(for: post)
        let linkRun = try #require(attributed.runs.first { $0.link != nil })

        #expect(linkRun.link == URL(string: "https://example.com"))
        #expect(String(attributed[linkRun.range].characters) == "여기")
    }

    @Test
    func attributedBodyWithoutLinksHasNoLinkRun() throws {
        let post = try makePost(body: "<p>그냥 평문입니다.</p>")

        let attributed = FeedPostRow.attributedBody(for: post)

        #expect(attributed.runs.allSatisfy { $0.link == nil })
        #expect(String(attributed.characters) == "그냥 평문입니다.")
    }

    @Test
    func attributedBodyMapsMultipleLinksInOrder() throws {
        let post = try makePost(
            body: "<p><a href=\"https://a.com\">first</a> / <a href=\"https://b.com\">second</a></p>"
        )

        let attributed = FeedPostRow.attributedBody(for: post)
        let linkURLs = attributed.runs.compactMap(\.link)

        #expect(linkURLs == [URL(string: "https://a.com"), URL(string: "https://b.com")])
    }

    private func makePost(body: String) throws -> FeedPost {
        let json = """
        {
          "id": 1,
          "slug": "p",
          "body": \(try encodeJSONString(body)),
          "post_type": "short",
          "status": "published",
          "created_at": "2026-06-13T00:30:00Z",
          "updated_at": "2026-06-13T00:31:00Z",
          "likes_count": 0,
          "boosts_count": 0,
          "liked": false,
          "boosted": false
        }
        """
        return try APIClient.decoder.decode(FeedPost.self, from: Data(json.utf8))
    }

    private func encodeJSONString(_ value: String) throws -> String {
        let data = try JSONEncoder().encode(value)
        return String(decoding: data, as: UTF8.self)
    }

    @Test
    func feedPostDecodesNullableFields() throws {
        let json = """
        {
          "id": 7,
          "slug": null,
          "body": "원격 포스트",
          "post_type": "comment",
          "status": null,
          "created_at": "2026-06-13T00:30:00Z",
          "updated_at": "2026-06-13T00:31:00Z",
          "likes_count": 0,
          "boosts_count": 0,
          "liked": false,
          "boosted": false,
          "author_name": null,
          "author_host": null,
          "article_slug": null,
          "parent_slug": null,
          "boosted_by": null
        }
        """

        let post = try APIClient.decoder.decode(FeedPost.self, from: Data(json.utf8))

        #expect(post.slug == nil)
        #expect(post.postType == .comment)
        #expect(post.status == nil)
        #expect(post.authorName == nil)
        #expect(post.authorHost == nil)
        #expect(post.articleSlug == nil)
        #expect(post.parentSlug == nil)
        #expect(post.boostedBy == nil)
        #expect(!post.isInteractive)
    }
}
