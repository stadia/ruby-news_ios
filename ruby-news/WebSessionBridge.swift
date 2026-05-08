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
    private let deleteSharedCookie: (HTTPCookie) -> Void
    private let deleteCookie: (HTTPCookie) async -> Void
    private let postChangeNotification: () -> Void

    init(
        baseURL: URL = AppEnvironment.baseURL,
        loadCookies: @escaping (URL) -> [HTTPCookie],
        setCookie: @escaping (HTTPCookie) async -> Void = { _ in },
        deleteSharedCookie: @escaping (HTTPCookie) -> Void = { _ in },
        deleteCookie: @escaping (HTTPCookie) async -> Void = { _ in },
        postChangeNotification: @escaping () -> Void = {}
    ) {
        self.baseURL = baseURL
        self.loadCookies = loadCookies
        self.setCookie = setCookie
        self.deleteSharedCookie = deleteSharedCookie
        self.deleteCookie = deleteCookie
        self.postChangeNotification = postChangeNotification
    }

    init(
        baseURL: URL = AppEnvironment.baseURL,
        sharedCookieStorage: HTTPCookieStorage = .shared,
        webCookieStore: WKHTTPCookieStore = WKWebsiteDataStore.default().httpCookieStore,
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
            postChangeNotification: {
                notificationCenter.post(name: Self.didChangeNotification, object: nil)
            }
        )
    }

    func syncSharedCookiesToWebView() async {
        for cookie in loadCookies(baseURL) {
            await setCookie(cookie)
        }
    }

    func clearCookies() async {
        for cookie in loadCookies(baseURL) {
            deleteSharedCookie(cookie)
            await deleteCookie(cookie)
        }
    }

    func notifyWebSessionChange() {
        postChangeNotification()
    }
}
