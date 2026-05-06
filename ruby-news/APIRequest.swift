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

    func urlRequest(relativeTo baseURL: URL = AppEnvironment.baseURL) -> URLRequest {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.percentEncodedPath = path
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        var request = URLRequest(url: components.url!)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}
