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

        return APIRequest(path: "/tag/\(encodedPathSegment(keyword))", queryItems: queryItems)
    }

    func urlRequest(relativeTo baseURL: URL = AppEnvironment.baseURL, accessToken: String? = nil) -> URLRequest {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.percentEncodedPath = path
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        var request = URLRequest(url: components.url!)
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
