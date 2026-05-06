//
//  APIClient.swift
//  ruby-news
//
//  Created by JEFF.DEAN on 5/7/26.
//

import Foundation

struct APIClient {
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    var baseURL: URL = AppEnvironment.baseURL
    var session: URLSession = .shared

    func articles(page: Int? = nil, searchQuery: String? = nil) async throws -> ArticlesResponse {
        var queryItems: [URLQueryItem] = []
        if let searchQuery, !searchQuery.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: searchQuery))
        }
        if let page {
            queryItems.append(URLQueryItem(name: "page", value: String(page)))
        }

        let request = APIRequest(path: "/articles", queryItems: queryItems).urlRequest(relativeTo: baseURL)
        let (data, response) = try await session.data(for: request)

        try validate(response)
        return try Self.decoder.decode(ArticlesResponse.self, from: data)
    }

    private func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.unacceptableStatusCode(httpResponse.statusCode)
        }
    }
}

enum APIError: Error, Equatable {
    case unacceptableStatusCode(Int)
}
