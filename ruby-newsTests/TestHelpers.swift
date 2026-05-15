//
//  TestHelpers.swift
//  ruby-newsTests
//

import Foundation
import Testing
@testable import ruby_news

enum TestHelpers {
    static func articlesResponse(slugs: [String], nextPage: String?) throws -> ArticlesResponse {
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

    static func makeArticle(slug: String, liked: Bool, likersCount: Int) throws -> NewsArticle {
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

    static func makeCookie(name: String, value: String, domain: String, path: String = "/") throws -> HTTPCookie {
        let properties: [HTTPCookiePropertyKey: Any] = [
            .name: name,
            .value: value,
            .domain: domain,
            .path: path,
            .secure: "FALSE"
        ]
        return try #require(HTTPCookie(properties: properties))
    }

    static func requestBodyData(from request: URLRequest) -> Data? {
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

final class LockedBox<Value>: @unchecked Sendable {
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
