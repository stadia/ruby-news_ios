//
//  WebRoute.swift
//  ruby-news
//
//  Created by JEFF.DEAN on 5/7/26.
//

import Foundation

enum WebRoute: Equatable {
    case login
    case signup
    case account
    case accountPassword
    case feed
    case article(id: String)
    case post(id: String)
    case profile(username: String)
    case followers(username: String)
    case following(username: String)
    case actor(id: String)
    case actorLookup
    case tag(keyword: String)

    func url(relativeTo baseURL: URL = AppEnvironment.baseURL) -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            preconditionFailure("Invalid base URL: \(baseURL)")
        }
        components.percentEncodedPath = path
        guard let url = components.url else {
            preconditionFailure("Invalid URL components for path: \(path)")
        }
        return url
    }

    private var path: String {
        switch self {
        case .login:
            return "/login"
        case .signup:
            return "/account/signup"
        case .account:
            return "/account/edit"
        case .accountPassword:
            return "/account/password"
        case .feed:
            return "/feed"
        case .article(let id):
            return "/articles/\(Self.encodedPathSegment(id))"
        case .post(let id):
            return "/posts/\(Self.encodedPathSegment(id))"
        case .profile(let username):
            return "/@\(Self.encodedPathSegment(username))"
        case .followers(let username):
            return "/@\(Self.encodedPathSegment(username))/followers"
        case .following(let username):
            return "/@\(Self.encodedPathSegment(username))/following"
        case .actor(let id):
            return "/actors/\(Self.encodedPathSegment(id))"
        case .actorLookup:
            return "/actors/lookup"
        case .tag(let keyword):
            return "/tag/\(Self.encodedPathSegment(keyword))"
        }
    }

    private static func encodedPathSegment(_ value: String) -> String {
        var allowedCharacters = CharacterSet.urlPathAllowed
        allowedCharacters.remove(charactersIn: "/")
        return value.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? value
    }
}
