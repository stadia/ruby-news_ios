//
//  WebAuthEventMonitor.swift
//  ruby-news
//

import Foundation

enum WebSessionAuthenticationState {
    case authenticated
    case unauthenticated
    case indeterminate
}

struct WebAuthEventMonitor {
    private let hasNativeAuthSession: () -> Bool
    private let isProtectedURL: (URL) -> Bool
    private let webSessionAuthenticationState: () async -> WebSessionAuthenticationState
    private let handleExternalLogout: () async -> Void

    init(
        hasNativeAuthSession: @escaping () -> Bool,
        isProtectedURL: @escaping (URL) -> Bool,
        webSessionAuthenticationState: @escaping () async -> WebSessionAuthenticationState,
        handleExternalLogout: @escaping () async -> Void
    ) {
        self.hasNativeAuthSession = hasNativeAuthSession
        self.isProtectedURL = isProtectedURL
        self.webSessionAuthenticationState = webSessionAuthenticationState
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
            webSessionAuthenticationState: {
                do {
                    guard let accountURL = URL(string: "/account/edit", relativeTo: baseURL) else {
                        return .indeterminate
                    }
                    var request = URLRequest(url: accountURL)
                    request.setValue("application/json", forHTTPHeaderField: "Accept")
                    let (_, response) = try await session.data(for: request)
                    guard let httpResponse = response as? HTTPURLResponse else { return .indeterminate }
                    switch httpResponse.statusCode {
                    case 200..<300:
                        return .authenticated
                    case 401, 403:
                        return .unauthenticated
                    default:
                        return .indeterminate
                    }
                } catch {
                    return .indeterminate
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
            switch await webSessionAuthenticationState() {
            case .authenticated, .indeterminate:
                break
            case .unauthenticated:
                await handleExternalLogout()
            }
        }
    }
}
