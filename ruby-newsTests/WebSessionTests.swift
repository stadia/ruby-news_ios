//
//  WebSessionTests.swift
//  ruby-newsTests
//

import Foundation
import Testing
@testable import ruby_news

@Suite(.serialized)
struct WebSessionTests {
    @Test func webSessionBridgeCopiesSharedCookiesIntoWebViewStore() async throws {
        let baseURL = try #require(URL(string: "http://localhost:3000"))
        let sessionCookie = try TestHelpers.makeCookie(name: "_al_news_session", value: "cookie-value", domain: "localhost")
        var copiedCookies: [HTTPCookie] = []
        var persistedCookies: [PersistedWebSessionCookie] = []

        let bridge = WebSessionBridge(
            baseURL: baseURL,
            loadCookies: { url in
                #expect(url == baseURL)
                return [sessionCookie]
            },
            setCookie: { cookie in
                copiedCookies.append(cookie)
            },
            savePersistedCookies: { cookies in
                persistedCookies = cookies
            }
        )

        await bridge.syncSharedCookiesToWebView()

        #expect(copiedCookies.map(\.name) == ["_al_news_session"])
        #expect(persistedCookies.map(\.name) == ["_al_news_session"])
        #expect(persistedCookies.map(\.value) == ["cookie-value"])
    }

    @Test func webSessionBridgeRestoresPersistedCookiesIntoSharedStorage() async throws {
        let baseURL = try #require(URL(string: "http://localhost:3000"))
        let persistedCookie = PersistedWebSessionCookie(
            name: "_al_news_session",
            value: "cookie-value",
            domain: "localhost",
            path: "/",
            isSecure: false,
            expiresDate: nil
        )
        var restoredCookies: [HTTPCookie] = []

        let bridge = WebSessionBridge(
            baseURL: baseURL,
            loadCookies: { _ in [] },
            storeSharedCookie: { cookie, url in
                #expect(url == baseURL)
                restoredCookies.append(cookie)
            },
            loadPersistedCookies: { [persistedCookie] }
        )

        bridge.restorePersistedCookiesToSharedStorage()

        #expect(restoredCookies.map(\.name) == ["_al_news_session"])
        #expect(restoredCookies.map(\.value) == ["cookie-value"])
    }

    @Test func webSessionBridgeClearsSharedWebAndPersistedCookies() async throws {
        let baseURL = try #require(URL(string: "http://localhost:3000"))
        let sessionCookie = try TestHelpers.makeCookie(name: "_al_news_session", value: "cookie-value", domain: "localhost")
        var deletedWebCookies: [HTTPCookie] = []
        var deletedSharedCookies: [HTTPCookie] = []
        var didClearPersistedCookies = false

        let bridge = WebSessionBridge(
            baseURL: baseURL,
            loadCookies: { _ in [sessionCookie] },
            deleteSharedCookie: { cookie in deletedSharedCookies.append(cookie) },
            deleteCookie: { cookie in deletedWebCookies.append(cookie) },
            clearPersistedCookies: { didClearPersistedCookies = true }
        )

        await bridge.clearCookies()

        #expect(deletedSharedCookies.map(\.name) == ["_al_news_session"])
        #expect(deletedWebCookies.map(\.name) == ["_al_news_session"])
        #expect(didClearPersistedCookies)
    }

    @Test func webAuthEventMonitorTriggersExternalLogoutWhenProtectedWebSessionIsGone() async throws {
        let logoutCount = LockedBox(0)
        let monitor = WebAuthEventMonitor(
            hasNativeAuthSession: { true },
            isProtectedURL: { _ in true },
            webSessionAuthenticationState: { .unauthenticated },
            handleExternalLogout: { logoutCount.value += 1 }
        )

        monitor.requestDidFinish(at: try #require(URL(string: "https://ruby-news.dev/feed")))
        try await Task.sleep(for: .milliseconds(50))

        #expect(logoutCount.value == 1)
    }

    @Test func webAuthEventMonitorSkipsSessionCheckWithoutNativeAuth() async throws {
        let logoutCount = LockedBox(0)
        let monitor = WebAuthEventMonitor(
            hasNativeAuthSession: { false },
            isProtectedURL: { _ in true },
            webSessionAuthenticationState: {
                Issue.record("Should not check web session without native auth")
                return .unauthenticated
            },
            handleExternalLogout: { logoutCount.value += 1 }
        )

        monitor.requestDidFinish(at: try #require(URL(string: "https://ruby-news.dev/feed")))
        try await Task.sleep(for: .milliseconds(50))

        #expect(logoutCount.value == 0)
    }

    @Test func webAuthEventMonitorSkipsPublicURLs() async throws {
        let logoutCount = LockedBox(0)
        let monitor = WebAuthEventMonitor(
            hasNativeAuthSession: { true },
            isProtectedURL: { _ in false },
            webSessionAuthenticationState: {
                Issue.record("Should not check public URLs")
                return .unauthenticated
            },
            handleExternalLogout: { logoutCount.value += 1 }
        )

        monitor.requestDidFinish(at: try #require(URL(string: "https://ruby-news.dev/@jeff")))
        try await Task.sleep(for: .milliseconds(50))

        #expect(logoutCount.value == 0)
    }

    @Test func webAuthEventMonitorKeepsSessionWhenAuthenticationIsIndeterminate() async throws {
        let logoutCount = LockedBox(0)
        let monitor = WebAuthEventMonitor(
            hasNativeAuthSession: { true },
            isProtectedURL: { _ in true },
            webSessionAuthenticationState: { .indeterminate },
            handleExternalLogout: { logoutCount.value += 1 }
        )

        monitor.requestDidFinish(at: try #require(URL(string: "https://ruby-news.dev/feed")))
        try await Task.sleep(for: .milliseconds(50))

        #expect(logoutCount.value == 0)
    }
}
