//
//  NewsArticle.swift
//  ruby-news
//
//  Created by JEFF.DEAN on 5/7/26.
//

import Foundation

struct ArticlesResponse: Decodable {
    let articles: [NewsArticle]
    let pagination: Pagination?
}

struct Pagination: Decodable, Equatable {
    let page: String?
    let nextPage: String?
    let limit: Int?

    enum CodingKeys: String, CodingKey {
        case page
        case next
        case nextPage
        case limit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        page = try container.decodeIfPresent(String.self, forKey: .page)
        nextPage = try container.decodeIfPresent(String.self, forKey: .nextPage)
            ?? container.decodeIfPresent(String.self, forKey: .next)
        limit = try container.decodeIfPresent(Int.self, forKey: .limit)
    }

    init(page: String? = nil, nextPage: String? = nil, limit: Int? = nil) {
        self.page = page
        self.nextPage = nextPage
        self.limit = limit
    }
}

struct NewsArticle: Decodable, Identifiable, Equatable {
    let slug: String
    let title: String
    let titleKo: String?
    let url: URL
    let host: String?
    let isRelated: Bool?
    var likersCount: Int
    var liked: Bool
    let postsCount: Int
    let publishedAt: Date?
    let summaryKey: [String]
    let tags: [String]

    var id: String { slug }
    var displayTitle: String { titleKo?.isEmpty == false ? titleKo! : title }
    var summary: String? { summaryKey.first }

    enum CodingKeys: String, CodingKey {
        case slug
        case title
        case titleKo
        case url
        case host
        case isRelated
        case likersCount
        case liked
        case postsCount
        case publishedAt
        case summaryKey
        case tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        slug = try container.decode(String.self, forKey: .slug)
        title = try container.decode(String.self, forKey: .title)
        titleKo = try container.decodeIfPresent(String.self, forKey: .titleKo)
        url = try container.decode(URL.self, forKey: .url)
        host = try container.decodeIfPresent(String.self, forKey: .host)
        isRelated = try container.decodeIfPresent(Bool.self, forKey: .isRelated) ?? false
        likersCount = try container.decodeIfPresent(Int.self, forKey: .likersCount) ?? 0
        liked = try container.decodeIfPresent(Bool.self, forKey: .liked) ?? false
        postsCount = try container.decodeIfPresent(Int.self, forKey: .postsCount) ?? 0
        summaryKey = try container.decodeIfPresent([String].self, forKey: .summaryKey) ?? []
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []

        let publishedAtString = try container.decodeIfPresent(String.self, forKey: .publishedAt)
        publishedAt = publishedAtString.flatMap(Self.dateFormatter.date(from:))
    }

    func detailURL(relativeTo baseURL: URL = AppEnvironment.baseURL) -> URL {
        WebRoute.article(id: slug).url(relativeTo: baseURL)
    }

    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
