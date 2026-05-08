//
//  SessionStore.swift
//  ruby-news
//

import Foundation
import Observation

@MainActor
@Observable
final class SessionStore: NSObject {
    static let didExternalSignOutNotification = Notification.Name("SessionStore.didExternalSignOut")

    private let fetchAccount: () async throws -> APIClient.AccountResult
    private let loginAction: (String, String) async throws -> APIClient.LoginResult
    private let logoutAction: () async throws -> Void
    private let syncWebSession: () async -> Void
    private let clearWebSession: () async -> Void
    private let notifyWebSessionChange: () -> Void
    private let tokenStore: TokenStore

    var currentUser: CurrentUser?
    var authSession: AuthSession?
    var isLoading = false

    var isSignedIn: Bool { currentUser != nil }

    convenience init(apiClient: APIClient = APIClient(), tokenStore: TokenStore = KeychainTokenStore()) {
        var configuredClient = apiClient
        let webSessionBridge = WebSessionBridge(baseURL: apiClient.baseURL)

        configuredClient.tokenProvider = {
            try? tokenStore.load()
        }

        self.init(
            fetchAccount: { try await configuredClient.me() },
            loginAction: { email, password in
                try await configuredClient.login(email: email, password: password)
            },
            logoutAction: {
                try await configuredClient.logout()
            },
            syncWebSession: {
                await webSessionBridge.syncSharedCookiesToWebView()
            },
            clearWebSession: {
                await webSessionBridge.clearCookies()
            },
            notifyWebSessionChange: {
                webSessionBridge.notifyWebSessionChange()
            },
            tokenStore: tokenStore
        )

        configuredClient.onTokenRefreshed = { session in
            try? tokenStore.save(session)
        }
    }

    init(fetchAccount: @escaping () async throws -> APIClient.AccountResult,
         loginAction: @escaping (String, String) async throws -> APIClient.LoginResult,
         logoutAction: @escaping () async throws -> Void = {},
         syncWebSession: @escaping () async -> Void = {},
         clearWebSession: @escaping () async -> Void = {},
         notifyWebSessionChange: @escaping () -> Void = {},
         tokenStore: TokenStore = InMemoryTokenStore()) {
        self.fetchAccount = fetchAccount
        self.loginAction = loginAction
        self.logoutAction = logoutAction
        self.syncWebSession = syncWebSession
        self.clearWebSession = clearWebSession
        self.notifyWebSessionChange = notifyWebSessionChange
        self.tokenStore = tokenStore
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleExternalSignOutNotification),
            name: Self.didExternalSignOutNotification,
            object: nil
        )
    }

    convenience init(fetchCurrentUser: @escaping () async throws -> CurrentUser,
         loginAction: @escaping (String, String) async throws -> APIClient.LoginResult = { _, _ in throw APIError.unauthorized },
         logoutAction: @escaping () async throws -> Void = {},
         syncWebSession: @escaping () async -> Void = {},
         clearWebSession: @escaping () async -> Void = {},
         notifyWebSessionChange: @escaping () -> Void = {},
         tokenStore: TokenStore = InMemoryTokenStore()) {
        self.init(
            fetchAccount: {
                let user = try await fetchCurrentUser()
                return APIClient.AccountResult(user: user, auth: nil)
            },
            loginAction: loginAction,
            logoutAction: logoutAction,
            syncWebSession: syncWebSession,
            clearWebSession: clearWebSession,
            notifyWebSessionChange: notifyWebSessionChange,
            tokenStore: tokenStore
        )
    }

    @objc private func handleExternalSignOutNotification() {
        clear()
    }

    static func handleExternalLogout(
        tokenStore: TokenStore = KeychainTokenStore(),
        webSessionBridge: WebSessionBridge = WebSessionBridge(),
        clearWebSession: (() async -> Void)? = nil
    ) async {
        if let clearWebSession {
            await clearWebSession()
        } else {
            await webSessionBridge.clearCookies()
        }

        webSessionBridge.notifyWebSessionChange()
        try? tokenStore.delete()
        NotificationCenter.default.post(name: didExternalSignOutNotification, object: nil)
    }

    func refresh() async {
        isLoading = true
        do {
            let result = try await fetchAccount()
            currentUser = result.user
            if let auth = result.auth {
                authSession = auth
                try? tokenStore.save(auth)
            } else if let storedAuth = try? tokenStore.load() {
                authSession = storedAuth
            }
        } catch {
            currentUser = nil
            if case APIError.unauthorized = error {
                authSession = nil
                try? tokenStore.delete()
            }
            if case APIError.unacceptableStatusCode(401) = error {
                authSession = nil
                try? tokenStore.delete()
            }
        }
        isLoading = false
    }

    func login(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await loginAction(email, password)
            currentUser = result.user
            authSession = result.auth
            try? tokenStore.save(result.auth)
            await syncWebSession()
            notifyWebSessionChange()
        } catch {
            clear()
            throw error
        }
    }

    func logout() async {
        isLoading = true
        defer {
            clear()
            isLoading = false
        }

        try? await logoutAction()
        await clearWebSession()
        notifyWebSessionChange()
    }

    func save(authSession: AuthSession) {
        self.authSession = authSession
        try? tokenStore.save(authSession)
    }

    func restoreSession() {
        authSession = try? tokenStore.load()
    }

    func clear() {
        currentUser = nil
        authSession = nil
        try? tokenStore.delete()
    }
}
