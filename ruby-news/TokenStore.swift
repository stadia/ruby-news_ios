//
//  TokenStore.swift
//  ruby-news
//

import Foundation
import Security

protocol TokenStore: Sendable {
    func save(_ session: AuthSession) throws
    func load() throws -> AuthSession?
    func delete() throws
}

final class KeychainTokenStore: TokenStore, Sendable {
    private let service: String
    private let accessGroup: String?

    init(service: String = Bundle.main.bundleIdentifier ?? "kr.stadia.ruby-news",
         accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }

    func save(_ session: AuthSession) throws {
        let data = try JSONEncoder().encode(KeychainSession(from: session))
        let query = baseQuery()
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData as String] = data
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw TokenStoreError.saveFailed(status)
        }
    }

    func load() throws -> AuthSession? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            if status == errSecItemNotFound { return nil }
            throw TokenStoreError.loadFailed(status)
        }
        guard let data = result as? Data else { return nil }
        let keychainSession = try JSONDecoder().decode(KeychainSession.self, from: data)
        return keychainSession.toAuthSession()
    }

    func delete() throws {
        let query = baseQuery()
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw TokenStoreError.deleteFailed(status)
        }
    }

    private func baseQuery() -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "auth-session",
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }
}

/// Keychain-storable representation of AuthSession
/// Uses fixed String dates since AuthSession.expiresAt is a Date
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
        AuthSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt
        )
    }
}

/// In-memory TokenStore for testing
final class InMemoryTokenStore: TokenStore, @unchecked Sendable {
    private var _session: AuthSession?

    func save(_ session: AuthSession) throws {
        _session = session
    }

    func load() throws -> AuthSession? {
        _session
    }

    func delete() throws {
        _session = nil
    }
}

enum TokenStoreError: Error, LocalizedError {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let s): "Keychain save failed: \(s)"
        case .loadFailed(let s): "Keychain load failed: \(s)"
        case .deleteFailed(let s): "Keychain delete failed: \(s)"
        }
    }
}
