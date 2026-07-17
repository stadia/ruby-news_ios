//
//  APIRequest.swift
//  ruby-news
//
//  Created by JEFF.DEAN on 5/7/26.
//

import Foundation

struct APIRequest {
    let path: String
    var queryItems: [URLQueryItem] = []

    static func tag(keyword: String, cursor: String? = nil) -> APIRequest {
        var queryItems: [URLQueryItem] = []
        if let cursor {
            queryItems.append(URLQueryItem(name: "page", value: cursor))
        }

        return APIRequest(path: "/api/v1/articles/tag/\(encodedPathSegment(keyword))", queryItems: queryItems)
    }

    func urlRequest(relativeTo baseURL: URL = AppEnvironment.baseURL, accessToken: String? = nil) -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            preconditionFailure("Invalid base URL: \(baseURL)")
        }
        components.percentEncodedPath = path
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            preconditionFailure("Invalid URL components for path: \(path)")
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private static func encodedPathSegment(_ value: String) -> String {
        var allowedCharacters = CharacterSet.urlPathAllowed
        allowedCharacters.remove(charactersIn: "/")
        return value.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? value
    }
}
