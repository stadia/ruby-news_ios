//
//  TokenStore.swift
//  ruby-news
//

import Foundation
@preconcurrency import KeychainAccess

nonisolated protocol TokenStore: Sendable {
    func save(_ session: AuthSession) throws
    func load() throws -> AuthSession?
    func delete() throws
}

nonisolated final class KeychainTokenStore: TokenStore, Sendable {
    private let keychain: Keychain

    nonisolated init(service: String = Bundle.main.bundleIdentifier ?? "kr.stadia.ruby-news") {
        self.keychain = Keychain(service: service)
    }

    nonisolated func save(_ session: AuthSession) throws {
        let data = try JSONEncoder().encode(KeychainSession(from: session))
        try keychain.set(data, key: "auth-session")
    }

    nonisolated func load() throws -> AuthSession? {
        guard let data = try keychain.getData("auth-session") else { return nil }
        return try JSONDecoder().decode(KeychainSession.self, from: data).toAuthSession()
    }

    nonisolated func delete() throws {
        try keychain.remove("auth-session")
    }
}

private struct KeychainSession: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date

    init(from session: AuthSession) {
        self.accessToken = session.accessToken
        self.refreshToken = session.refreshToken
        self.expiresAt = session.expiresAt
    }

    func toAuthSession() -> AuthSession {
        AuthSession(accessToken: accessToken, refreshToken: refreshToken, expiresAt: expiresAt)
    }
}

/// In-memory TokenStore for testing
nonisolated final class InMemoryTokenStore: TokenStore, @unchecked Sendable {
    private var _session: AuthSession?

    nonisolated init() {}

    nonisolated func save(_ session: AuthSession) throws { _session = session }
    nonisolated func load() throws -> AuthSession? { _session }
    nonisolated func delete() throws { _session = nil }
}
