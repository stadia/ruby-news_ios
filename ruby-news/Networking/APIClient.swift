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
    var tokenProvider: (@Sendable () -> AuthSession?)?
    var onTokenRefreshed: (@Sendable (AuthSession) -> Void)?

    func articles(cursor: String? = nil, searchQuery: String? = nil) async throws -> ArticlesResponse {
        var queryItems: [URLQueryItem] = []
        if let searchQuery, !searchQuery.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: searchQuery))
        }
        if let cursor {
            queryItems.append(URLQueryItem(name: "page", value: cursor))
        }

        return try await withAuthRetry {
            let accessToken = tokenProvider?()?.accessToken
            let request = APIRequest(path: "/articles", queryItems: queryItems).urlRequest(relativeTo: baseURL, accessToken: accessToken)
            let (data, response) = try await session.data(for: request)
            try validate(response)
            return try Self.decoder.decode(ArticlesResponse.self, from: data)
        }
    }

    func others(cursor: String? = nil) async throws -> ArticlesResponse {
        return try await withAuthRetry {
            let accessToken = tokenProvider?()?.accessToken
            var queryItems: [URLQueryItem] = []
            if let cursor {
                queryItems.append(URLQueryItem(name: "page", value: cursor))
            }
            let request = APIRequest(path: "/others", queryItems: queryItems).urlRequest(relativeTo: baseURL, accessToken: accessToken)
            let (data, response) = try await session.data(for: request)
            try validate(response)
            return try Self.decoder.decode(ArticlesResponse.self, from: data)
        }
    }

    func tag(keyword: String, cursor: String? = nil) async throws -> ArticlesResponse {
        return try await withAuthRetry {
            let accessToken = tokenProvider?()?.accessToken
            let request = APIRequest.tag(keyword: keyword, cursor: cursor).urlRequest(relativeTo: baseURL, accessToken: accessToken)
            let (data, response) = try await session.data(for: request)
            try validate(response)
            return try Self.decoder.decode(ArticlesResponse.self, from: data)
        }
    }

    struct AccountResult {
        let user: CurrentUser
        let auth: AuthSession?
    }

    func me() async throws -> AccountResult {
        return try await withAuthRetry {
            let accessToken = tokenProvider?()?.accessToken
            let request = APIRequest(path: "/account/edit").urlRequest(relativeTo: baseURL, accessToken: accessToken)
            let (data, response) = try await session.data(for: request)
            try validate(response)
            let accountResponse = try Self.decoder.decode(AccountResponse.self, from: data)
            let auth = accountResponse.auth?.toAuthSession()
            return AccountResult(user: accountResponse.user, auth: auth)
        }
    }

    func refreshTokens(refreshToken: String) async throws -> AuthSession {
        var request = URLRequest(url: URL(string: "/api/v1/auth/refresh", relativeTo: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["refresh_token": refreshToken])

        let (data, response) = try await session.data(for: request)
        try validate(response)
        let tokenResponse = try Self.decoder.decode(RefreshTokenResponse.self, from: data)
        return tokenResponse.toAuthSession()
    }

    func logout() async throws {
        try await withAuthRetry {
            guard let accessToken = tokenProvider?()?.accessToken else { return }

            var request = APIRequest(path: "/logout").urlRequest(relativeTo: baseURL, accessToken: accessToken)
            request.httpMethod = "GET"

            let (_, response) = try await session.data(for: request)
            try validate(response)
        }
    }

    struct LoginResult {
        let user: CurrentUser
        let auth: AuthSession
    }

    func like(articleSlug: String) async throws -> LikeResponse {
        try await sendLikeRequest(articleSlug: articleSlug, method: "POST")
    }

    func unlike(articleSlug: String) async throws -> LikeResponse {
        try await sendLikeRequest(articleSlug: articleSlug, method: "DELETE")
    }

    func login(email: String, password: String) async throws -> LoginResult {
        var request = URLRequest(url: URL(string: "/login", relativeTo: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode([
            "user": ["email": email, "password": password]
        ])

        let (data, response) = try await session.data(for: request)
        let httpResponse = try validateLogin(response)
        let loginBody = try Self.decoder.decode(LoginResponse.self, from: data)

        guard let authSession = AuthSession(
            authorizationHeader: httpResponse.value(forHTTPHeaderField: "Authorization"),
            refreshToken: loginBody.refreshToken,
            expiresIn: 900
        ) else {
            throw APIError.missingAccessToken
        }

        return LoginResult(user: loginBody.user, auth: authSession)
    }

    private func sendLikeRequest(articleSlug: String, method: String) async throws -> LikeResponse {
        try await withAuthRetry {
            let accessToken = tokenProvider?()?.accessToken
            var request = APIRequest(path: "/articles/\(articleSlug)/like").urlRequest(relativeTo: baseURL, accessToken: accessToken)
            request.httpMethod = method
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(["likeable_type": "Article"])

            let (data, response) = try await session.data(for: request)
            try validate(response)
            return try Self.decoder.decode(LikeResponse.self, from: data)
        }
    }

    private func validateLogin(_ response: URLResponse) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unacceptableStatusCode(0)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.unacceptableStatusCode(httpResponse.statusCode)
        }
        return httpResponse
    }

    private func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.unacceptableStatusCode(httpResponse.statusCode)
        }
    }

    private func withAuthRetry<T>(_ action: () async throws -> T) async throws -> T {
        do {
            return try await action()
        } catch APIError.unacceptableStatusCode(401) {
            guard (try? await attemptRefresh()) != nil else {
                throw APIError.unauthorized
            }
            return try await action()
        }
    }

    private func attemptRefresh() async throws -> AuthSession {
        guard let session = tokenProvider?(),
              let refreshToken = session.refreshToken else {
            throw APIError.unauthorized
        }
        let newSession = try await refreshTokens(refreshToken: refreshToken)
        onTokenRefreshed?(newSession)
        return newSession
    }
}

enum APIError: Error, Equatable {
    case unacceptableStatusCode(Int)
    case unauthorized
    case missingAccessToken
}

struct LoginResponse: Decodable {
    let user: CurrentUser
    let refreshToken: String
}

struct LikeResponse: Decodable, Equatable {
    let likeableType: String
    let likeableSlug: String
    let liked: Bool
    let likesCount: Int
}
