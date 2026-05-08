//
//  WebSessionBridge.swift
//  ruby-news
//

import Foundation
import WebKit

struct WebSessionBridge {
    static let didChangeNotification = Notification.Name("WebSessionBridge.didChange")

    let baseURL: URL
    private let loadCookies: (URL) -> [HTTPCookie]
    private let setCookie: (HTTPCookie) async -> Void
    private let storeSharedCookie: (HTTPCookie, URL) -> Void
    private let deleteSharedCookie: (HTTPCookie) -> Void
    private let deleteCookie: (HTTPCookie) async -> Void
    private let savePersistedCookies: ([PersistedWebSessionCookie]) -> Void
    private let loadPersistedCookies: () -> [PersistedWebSessionCookie]
    private let clearPersistedCookies: () -> Void
    private let postChangeNotification: () -> Void

    init(
        baseURL: URL = AppEnvironment.baseURL,
        loadCookies: @escaping (URL) -> [HTTPCookie],
        setCookie: @escaping (HTTPCookie) async -> Void = { _ in },
        storeSharedCookie: @escaping (HTTPCookie, URL) -> Void = { _, _ in },
        deleteSharedCookie: @escaping (HTTPCookie) -> Void = { _ in },
        deleteCookie: @escaping (HTTPCookie) async -> Void = { _ in },
        savePersistedCookies: @escaping ([PersistedWebSessionCookie]) -> Void = { _ in },
        loadPersistedCookies: @escaping () -> [PersistedWebSessionCookie] = { [] },
        clearPersistedCookies: @escaping () -> Void = {},
        postChangeNotification: @escaping () -> Void = {}
    ) {
        self.baseURL = baseURL
        self.loadCookies = loadCookies
        self.setCookie = setCookie
        self.storeSharedCookie = storeSharedCookie
        self.deleteSharedCookie = deleteSharedCookie
        self.deleteCookie = deleteCookie
        self.savePersistedCookies = savePersistedCookies
        self.loadPersistedCookies = loadPersistedCookies
        self.clearPersistedCookies = clearPersistedCookies
        self.postChangeNotification = postChangeNotification
    }

    init(
        baseURL: URL = AppEnvironment.baseURL,
        sharedCookieStorage: HTTPCookieStorage = .shared,
        webCookieStore: WKHTTPCookieStore = WKWebsiteDataStore.default().httpCookieStore,
        persistedCookieStore: WebSessionCookieStore = KeychainWebSessionCookieStore(),
        notificationCenter: NotificationCenter = .default
    ) {
        self.init(
            baseURL: baseURL,
            loadCookies: { url in
                sharedCookieStorage.cookies(for: url) ?? []
            },
            setCookie: { cookie in
                await withCheckedContinuation { continuation in
                    webCookieStore.setCookie(cookie) {
                        continuation.resume()
                    }
                }
            },
            storeSharedCookie: { cookie, url in
                sharedCookieStorage.setCookies([cookie], for: url, mainDocumentURL: url)
            },
            deleteSharedCookie: { cookie in
                sharedCookieStorage.deleteCookie(cookie)
            },
            deleteCookie: { cookie in
                await withCheckedContinuation { continuation in
                    webCookieStore.delete(cookie) {
                        continuation.resume()
                    }
                }
            },
            savePersistedCookies: { cookies in
                try? persistedCookieStore.save(cookies)
            },
            loadPersistedCookies: {
                (try? persistedCookieStore.load()) ?? []
            },
            clearPersistedCookies: {
                try? persistedCookieStore.delete()
            },
            postChangeNotification: {
                notificationCenter.post(name: Self.didChangeNotification, object: nil)
            }
        )
    }

    func restorePersistedCookiesToSharedStorage() {
        for persistedCookie in loadPersistedCookies() {
            guard let cookie = persistedCookie.toHTTPCookie() else { continue }
            storeSharedCookie(cookie, baseURL)
        }
    }

    func syncSharedCookiesToWebView() async {
        persistSharedCookies()
        for cookie in loadCookies(baseURL) {
            await setCookie(cookie)
        }
    }

    func persistSharedCookies() {
        savePersistedCookies(loadCookies(baseURL).map(PersistedWebSessionCookie.init(cookie:)))
    }

    func clearCookies() async {
        clearPersistedCookies()
        for cookie in loadCookies(baseURL) {
            deleteSharedCookie(cookie)
            await deleteCookie(cookie)
        }
    }

    func notifyWebSessionChange() {
        postChangeNotification()
    }
}
