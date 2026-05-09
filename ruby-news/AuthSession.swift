//
//  AuthSession.swift
//  ruby-news
//

import Foundation

nonisolated struct AuthSession: Equatable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date

    var isExpired: Bool {
        expiresAt < Date()
    }

    init(accessToken: String, refreshToken: String? = nil, expiresAt: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }

    init?(authorizationHeader: String?, refreshToken: String? = nil, expiresIn: Int = 900) {
        guard let header = authorizationHeader,
              header.hasPrefix("Bearer "),
              !header.isEmpty else {
            return nil
        }
        let token = String(header.dropFirst("Bearer ".count))
        guard !token.isEmpty else { return nil }

        self.accessToken = token
        self.refreshToken = refreshToken
        self.expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
    }
}

nonisolated struct RefreshTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int

    func toAuthSession() -> AuthSession {
        AuthSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(expiresIn))
        )
    }
}
