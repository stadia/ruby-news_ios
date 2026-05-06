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
    let page: Int?
    let nextPage: Int?
    let limit: Int?

    enum CodingKeys: String, CodingKey {
        case page
        case next
        case nextPage
        case limit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        page = try container.decodeIfPresent(Int.self, forKey: .page)
        nextPage = try container.decodeIfPresent(Int.self, forKey: .nextPage)
            ?? container.decodeIfPresent(Int.self, forKey: .next)
        limit = try container.decodeIfPresent(Int.self, forKey: .limit)
    }
}

struct NewsArticle: Decodable, Identifiable, Equatable {
    let slug: String
    let title: String
    let titleKo: String?
    let url: URL
    let host: String?
    let isRelated: Bool?
    let likersCount: Int
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
