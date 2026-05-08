//
//  WebSessionCookieStore.swift
//  ruby-news
//

import Foundation
import Security

struct PersistedWebSessionCookie: Codable, Equatable {
    let name: String
    let value: String
    let domain: String
    let path: String
    let isSecure: Bool
    let expiresDate: Date?

    init(cookie: HTTPCookie) {
        self.name = cookie.name
        self.value = cookie.value
        self.domain = cookie.domain
        self.path = cookie.path
        self.isSecure = cookie.isSecure
        self.expiresDate = cookie.expiresDate
    }

    init(name: String, value: String, domain: String, path: String, isSecure: Bool, expiresDate: Date?) {
        self.name = name
        self.value = value
        self.domain = domain
        self.path = path
        self.isSecure = isSecure
        self.expiresDate = expiresDate
    }

    func toHTTPCookie() -> HTTPCookie? {
        var properties: [HTTPCookiePropertyKey: Any] = [
            .name: name,
            .value: value,
            .domain: domain,
            .path: path,
            .secure: isSecure ? "TRUE" : "FALSE"
        ]

        if let expiresDate {
            properties[.expires] = expiresDate
        }

        return HTTPCookie(properties: properties)
    }
}

protocol WebSessionCookieStore: Sendable {
    func save(_ cookies: [PersistedWebSessionCookie]) throws
    func load() throws -> [PersistedWebSessionCookie]
    func delete() throws
}

final class KeychainWebSessionCookieStore: WebSessionCookieStore, Sendable {
    private let service: String
    private let accessGroup: String?

    init(service: String = Bundle.main.bundleIdentifier ?? "kr.stadia.ruby-news",
         accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }

    func save(_ cookies: [PersistedWebSessionCookie]) throws {
        let data = try JSONEncoder().encode(cookies)
        let query = baseQuery()
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData as String] = data
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw TokenStoreError.saveFailed(status)
        }
    }

    func load() throws -> [PersistedWebSessionCookie] {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            if status == errSecItemNotFound { return [] }
            throw TokenStoreError.loadFailed(status)
        }

        guard let data = result as? Data else { return [] }
        return try JSONDecoder().decode([PersistedWebSessionCookie].self, from: data)
    }

    func delete() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw TokenStoreError.deleteFailed(status)
        }
    }

    private func baseQuery() -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "web-session-cookies"
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }
}

final class InMemoryWebSessionCookieStore: WebSessionCookieStore, @unchecked Sendable {
    private var cookies: [PersistedWebSessionCookie] = []

    func save(_ cookies: [PersistedWebSessionCookie]) throws {
        self.cookies = cookies
    }

    func load() throws -> [PersistedWebSessionCookie] {
        cookies
    }

    func delete() throws {
        cookies = []
    }
}
