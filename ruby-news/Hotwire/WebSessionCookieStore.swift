//
//  WebSessionCookieStore.swift
//  ruby-news
//

import Foundation
import KeychainAccess

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
            .name: name, .value: value, .domain: domain, .path: path,
            .secure: isSecure ? "TRUE" : "FALSE"
        ]
        if let expiresDate { properties[.expires] = expiresDate }
        return HTTPCookie(properties: properties)
    }
}

protocol WebSessionCookieStore: Sendable {
    func save(_ cookies: [PersistedWebSessionCookie]) throws
    func load() throws -> [PersistedWebSessionCookie]
    func delete() throws
}

final class KeychainWebSessionCookieStore: WebSessionCookieStore, Sendable {
    private let keychain: Keychain

    init(service: String = Bundle.main.bundleIdentifier ?? "kr.stadia.ruby-news") {
        self.keychain = Keychain(service: service)
    }

    func save(_ cookies: [PersistedWebSessionCookie]) throws {
        let data = try JSONEncoder().encode(cookies)
        try keychain.set(data, key: "web-session-cookies")
    }

    func load() throws -> [PersistedWebSessionCookie] {
        guard let data = try keychain.getData("web-session-cookies") else { return [] }
        return try JSONDecoder().decode([PersistedWebSessionCookie].self, from: data)
    }

    func delete() throws {
        try keychain.remove("web-session-cookies")
    }
}

final class InMemoryWebSessionCookieStore: WebSessionCookieStore, @unchecked Sendable {
    private var cookies: [PersistedWebSessionCookie] = []

    func save(_ cookies: [PersistedWebSessionCookie]) throws { self.cookies = cookies }
    func load() throws -> [PersistedWebSessionCookie] { cookies }
    func delete() throws { cookies = [] }
}
