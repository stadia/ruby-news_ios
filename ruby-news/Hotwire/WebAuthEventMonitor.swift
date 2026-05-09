//
//  WebAuthEventMonitor.swift
//  ruby-news
//

import Foundation

struct WebAuthEventMonitor {
    private let hasNativeAuthSession: () -> Bool
    private let isProtectedURL: (URL) -> Bool
    private let webSessionIsAuthenticated: () async -> Bool
    private let handleExternalLogout: () async -> Void

    init(
        hasNativeAuthSession: @escaping () -> Bool,
        isProtectedURL: @escaping (URL) -> Bool,
        webSessionIsAuthenticated: @escaping () async -> Bool,
        handleExternalLogout: @escaping () async -> Void
    ) {
        self.hasNativeAuthSession = hasNativeAuthSession
        self.isProtectedURL = isProtectedURL
        self.webSessionIsAuthenticated = webSessionIsAuthenticated
        self.handleExternalLogout = handleExternalLogout
    }

    init(
        baseURL: URL = AppEnvironment.baseURL,
        tokenStore: TokenStore = KeychainTokenStore(),
        session: URLSession = .shared,
        handleExternalLogout: @escaping () async -> Void = {
            await SessionStore.handleExternalLogout()
        }
    ) {
        self.init(
            hasNativeAuthSession: {
                (try? tokenStore.load()) != nil
            },
            isProtectedURL: { url in
                let path = url.path
                return path == "/feed" || path.hasPrefix("/account")
            },
            webSessionIsAuthenticated: {
                do {
                    var request = URLRequest(url: URL(string: "/account/edit", relativeTo: baseURL)!)
                    request.setValue("application/json", forHTTPHeaderField: "Accept")
                    let (_, response) = try await session.data(for: request)
                    guard let httpResponse = response as? HTTPURLResponse else { return false }
                    return (200..<300).contains(httpResponse.statusCode)
                } catch {
                    return false
                }
            },
            handleExternalLogout: handleExternalLogout
        )
    }

    func requestDidFinish(at url: URL) {
        verifyWebSessionIfNeeded(after: url)
    }

    func formSubmissionDidFinish(at url: URL) {
        verifyWebSessionIfNeeded(after: url)
    }

    private func verifyWebSessionIfNeeded(after url: URL) {
        guard hasNativeAuthSession(), isProtectedURL(url) else { return }

        Task {
            if await webSessionIsAuthenticated() {
                return
            }
            await handleExternalLogout()
        }
    }
}
