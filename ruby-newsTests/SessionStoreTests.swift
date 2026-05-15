//
//  SessionStoreTests.swift
//  ruby-newsTests
//

import Foundation
import Testing
@testable import ruby_news

@MainActor
@Suite(.serialized)
struct SessionStoreTests {
    @Test func sessionStoreRefreshSetsCurrentUserOnSuccess() async throws {
        let sessionStore = SessionStore(fetchCurrentUser: {
            CurrentUser(id: 1, email: "jeff@example.com", name: "Jeff", username: "jeff", avatarURL: nil)
        })

        #expect(!sessionStore.isSignedIn)

        await sessionStore.refresh()
        #expect(sessionStore.isSignedIn)
        #expect(sessionStore.currentUser?.username == "jeff")
        #expect(!sessionStore.isLoading)
    }

    @Test func sessionStoreRefreshClearsUserOnUnauthorized() async throws {
        let tokenStore = InMemoryTokenStore()
        try tokenStore.save(
            AuthSession(
                accessToken: "stale-access",
                refreshToken: "stale-refresh",
                expiresAt: Date().addingTimeInterval(900)
            )
        )
        let sessionStore = SessionStore(
            fetchCurrentUser: {
                throw APIError.unacceptableStatusCode(401)
            },
            tokenStore: tokenStore
        )
        sessionStore.restoreSession()

        await sessionStore.refresh()
        #expect(!sessionStore.isSignedIn)
        #expect(sessionStore.currentUser == nil)
        #expect(sessionStore.authSession == nil)
        #expect(try tokenStore.load() == nil)
        #expect(!sessionStore.isLoading)
    }

    @Test func sessionStoreClearResetsUser() async {
        let sessionStore = SessionStore(fetchCurrentUser: {
            CurrentUser(id: 1, email: "jeff@example.com", name: "Jeff", username: "jeff", avatarURL: nil)
        })

        await sessionStore.refresh()
        #expect(sessionStore.isSignedIn)

        sessionStore.clear()
        #expect(!sessionStore.isSignedIn)
        #expect(sessionStore.currentUser == nil)
    }

    @Test func sessionStoreSavesAndClearsAuthSession() async throws {
        let tokenStore = InMemoryTokenStore()
        let sessionStore = SessionStore(
            fetchCurrentUser: { throw APIError.unauthorized },
            tokenStore: tokenStore
        )

        let session = AuthSession(
            accessToken: "access",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(900)
        )

        sessionStore.save(authSession: session)
        #expect(sessionStore.authSession?.accessToken == "access")
        #expect(try tokenStore.load()?.accessToken == "access")

        sessionStore.clear()
        #expect(sessionStore.authSession == nil)
        #expect(sessionStore.currentUser == nil)
        #expect(try tokenStore.load() == nil)
    }

    @Test func sessionStoreRestoresSessionFromTokenStore() async throws {
        let tokenStore = InMemoryTokenStore()
        let session = AuthSession(
            accessToken: "restored-access",
            refreshToken: "restored-refresh",
            expiresAt: Date().addingTimeInterval(900)
        )
        try tokenStore.save(session)

        let sessionStore = SessionStore(
            fetchCurrentUser: { throw APIError.unauthorized },
            tokenStore: tokenStore
        )

        #expect(sessionStore.authSession == nil)

        sessionStore.restoreSession()
        #expect(sessionStore.authSession?.accessToken == "restored-access")
        #expect(sessionStore.authSession?.refreshToken == "restored-refresh")
    }

    @Test func sessionStoreLoginSetsUserAndAuth() async throws {
        let tokenStore = InMemoryTokenStore()
        let expectedUser = CurrentUser(id: 1, email: "jeff@example.com", name: "Jeff", username: "jeff", avatarURL: nil)
        let expectedAuth = AuthSession(
            accessToken: "native-access",
            refreshToken: "native-refresh",
            expiresAt: Date().addingTimeInterval(900)
        )

        let sessionStore = SessionStore(
            fetchAccount: { throw APIError.unauthorized },
            loginAction: { email, password in
                #expect(email == "jeff@example.com")
                #expect(password == "password")
                return APIClient.LoginResult(user: expectedUser, auth: expectedAuth)
            },
            tokenStore: tokenStore
        )

        try await sessionStore.login(email: "jeff@example.com", password: "password")

        #expect(sessionStore.isSignedIn)
        #expect(sessionStore.currentUser?.username == "jeff")
        #expect(sessionStore.authSession?.accessToken == "native-access")
        #expect(sessionStore.authSession?.refreshToken == "native-refresh")

        let stored = try #require(try tokenStore.load())
        #expect(stored.accessToken == "native-access")
        #expect(stored.refreshToken == "native-refresh")
    }

    @Test func sessionStoreLoginLeavesStateUnchangedOnFailure() async throws {
        let tokenStore = InMemoryTokenStore()
        let sessionStore = SessionStore(
            fetchAccount: { throw APIError.unauthorized },
            loginAction: { _, _ in throw APIError.unacceptableStatusCode(401) },
            tokenStore: tokenStore
        )

        do {
            try await sessionStore.login(email: "wrong@example.com", password: "wrong")
            Issue.record("Expected login to throw")
        } catch APIError.unacceptableStatusCode(401) {
            // expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(!sessionStore.isSignedIn)
        #expect(sessionStore.authSession == nil)
        #expect(try tokenStore.load() == nil)
    }

    @Test func sessionStoreLoginSyncsWebSessionAndBroadcastsChange() async throws {
        let tokenStore = InMemoryTokenStore()
        let expectedUser = CurrentUser(id: 1, email: "jeff@example.com", name: "Jeff", username: "jeff", avatarURL: nil)
        let expectedAuth = AuthSession(
            accessToken: "native-access",
            refreshToken: "native-refresh",
            expiresAt: Date().addingTimeInterval(900)
        )
        var didSyncWebSession = false
        var didNotifyWebSessionChange = false

        let sessionStore = SessionStore(
            fetchAccount: { throw APIError.unauthorized },
            loginAction: { _, _ in
                APIClient.LoginResult(user: expectedUser, auth: expectedAuth)
            },
            syncWebSession: { didSyncWebSession = true },
            notifyWebSessionChange: { didNotifyWebSessionChange = true },
            tokenStore: tokenStore
        )

        try await sessionStore.login(email: "jeff@example.com", password: "password")

        #expect(didSyncWebSession)
        #expect(didNotifyWebSessionChange)
    }

    @Test func sessionStoreLogoutClearsLocalStateAfterSuccessfulRequest() async throws {
        let tokenStore = InMemoryTokenStore()
        let existingUser = CurrentUser(id: 1, email: "jeff@example.com", name: "Jeff", username: "jeff", avatarURL: nil)
        let existingAuth = AuthSession(accessToken: "jwt-token", refreshToken: "refresh", expiresAt: Date().addingTimeInterval(900))
        var logoutCalled = false

        let sessionStore = SessionStore(
            fetchAccount: { throw APIError.unauthorized },
            loginAction: { _, _ in throw APIError.unauthorized },
            logoutAction: { logoutCalled = true },
            tokenStore: tokenStore
        )
        sessionStore.currentUser = existingUser
        sessionStore.authSession = existingAuth
        try tokenStore.save(existingAuth)

        await sessionStore.logout()

        #expect(logoutCalled)
        #expect(sessionStore.currentUser == nil)
        #expect(sessionStore.authSession == nil)
        #expect(try tokenStore.load() == nil)
    }

    @Test func sessionStoreLogoutClearsLocalStateEvenWhenRequestFails() async throws {
        let tokenStore = InMemoryTokenStore()
        let existingUser = CurrentUser(id: 1, email: "jeff@example.com", name: "Jeff", username: "jeff", avatarURL: nil)
        let existingAuth = AuthSession(accessToken: "jwt-token", refreshToken: "refresh", expiresAt: Date().addingTimeInterval(900))

        let sessionStore = SessionStore(
            fetchAccount: { throw APIError.unauthorized },
            loginAction: { _, _ in throw APIError.unauthorized },
            logoutAction: { throw APIError.unacceptableStatusCode(500) },
            tokenStore: tokenStore
        )
        sessionStore.currentUser = existingUser
        sessionStore.authSession = existingAuth
        try tokenStore.save(existingAuth)

        await sessionStore.logout()

        #expect(sessionStore.currentUser == nil)
        #expect(sessionStore.authSession == nil)
        #expect(try tokenStore.load() == nil)
    }

    @Test func sessionStoreLogoutClearsWebSessionAndBroadcastsChangeEvenWhenRequestFails() async throws {
        let tokenStore = InMemoryTokenStore()
        let existingUser = CurrentUser(id: 1, email: "jeff@example.com", name: "Jeff", username: "jeff", avatarURL: nil)
        let existingAuth = AuthSession(accessToken: "jwt-token", refreshToken: "refresh", expiresAt: Date().addingTimeInterval(900))
        var didClearWebSession = false
        var didNotifyWebSessionChange = false

        let sessionStore = SessionStore(
            fetchAccount: { throw APIError.unauthorized },
            loginAction: { _, _ in throw APIError.unauthorized },
            logoutAction: { throw APIError.unacceptableStatusCode(500) },
            clearWebSession: { didClearWebSession = true },
            notifyWebSessionChange: { didNotifyWebSessionChange = true },
            tokenStore: tokenStore
        )
        sessionStore.currentUser = existingUser
        sessionStore.authSession = existingAuth
        try tokenStore.save(existingAuth)

        await sessionStore.logout()

        #expect(didClearWebSession)
        #expect(didNotifyWebSessionChange)
        #expect(sessionStore.currentUser == nil)
        #expect(sessionStore.authSession == nil)
    }

    @Test func sessionStoreClearsStateWhenExternalSignOutIsHandled() async throws {
        let tokenStore = InMemoryTokenStore()
        let existingAuth = AuthSession(accessToken: "jwt-token", refreshToken: "refresh", expiresAt: Date().addingTimeInterval(900))
        let sessionStore = SessionStore(
            fetchAccount: { throw APIError.unauthorized },
            loginAction: { _, _ in throw APIError.unauthorized },
            tokenStore: tokenStore
        )
        sessionStore.currentUser = CurrentUser(id: 1, email: "jeff@example.com", name: "Jeff", username: "jeff", avatarURL: nil)
        sessionStore.authSession = existingAuth
        try tokenStore.save(existingAuth)

        var didClearWebSession = false
        var didNotifyWebSessionChange = false
        await SessionStore.handleExternalLogout(
            tokenStore: tokenStore,
            webSessionBridge: WebSessionBridge(
                loadCookies: { _ in [] },
                clearPersistedCookies: {},
                postChangeNotification: { didNotifyWebSessionChange = true }
            ),
            clearWebSession: { didClearWebSession = true }
        )

        await Task.yield()

        #expect(didClearWebSession)
        #expect(didNotifyWebSessionChange)
        #expect(sessionStore.currentUser == nil)
        #expect(sessionStore.authSession == nil)
        #expect(try tokenStore.load() == nil)
    }

    @Test func sessionStoreRefreshUpdatesAuthSessionAfterTokenRefreshRetry() async throws {
        let tokenStore = InMemoryTokenStore()
        let staleAuth = AuthSession(accessToken: "stale-access", refreshToken: "refresh-token", expiresAt: Date().addingTimeInterval(-60))
        try tokenStore.save(staleAuth)

        var meRequestCount = 0
        let session = URLSession.mockSession { request in
            let path = request.url?.path

            switch path {
            case "/account/edit":
                meRequestCount += 1
                let statusCode = meRequestCount == 1 ? 401 : 200
                let body = meRequestCount == 1
                    ? Data("{\"error\":\"unauthorized\"}".utf8)
                    : Data("{\"user\":{\"id\":1,\"email\":\"jeff@example.com\",\"name\":\"Jeff\",\"username\":\"jeff\",\"avatar_url\":null}}".utf8)
                let expectedAuth = meRequestCount == 1 ? "Bearer stale-access" : "Bearer fresh-access"
                #expect(request.value(forHTTPHeaderField: "Authorization") == expectedAuth)
                return (
                    HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                    body
                )
            case "/api/v1/auth/refresh":
                guard let body = TestHelpers.requestBodyData(from: request),
                      let payload = try? JSONSerialization.jsonObject(with: body) as? [String: String] else {
                    Issue.record("Expected refresh request body")
                    return (
                        HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                        Data("{\"access_token\":\"fresh-access\",\"refresh_token\":\"fresh-refresh\",\"expires_in\":900}".utf8)
                    )
                }
                #expect(payload["refresh_token"] == "refresh-token")
                return (
                    HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                    Data("{\"access_token\":\"fresh-access\",\"refresh_token\":\"fresh-refresh\",\"expires_in\":900}".utf8)
                )
            default:
                Issue.record("Unexpected path: \(path ?? "nil")")
                return (
                    HTTPURLResponse(url: request.url ?? URL(string: "http://localhost:3000")!, statusCode: 404, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                    nil
                )
            }
        }

        let client = APIClient.authenticated(tokenStore: tokenStore, baseURL: URL(string: "http://localhost:3000")!, session: session)
        let sessionStore = SessionStore(apiClient: client, tokenStore: tokenStore)
        sessionStore.restoreSession()

        await sessionStore.refresh()

        #expect(sessionStore.currentUser?.username == "jeff")
        #expect(sessionStore.authSession?.accessToken == "fresh-access")
        #expect(sessionStore.authSession?.refreshToken == "fresh-refresh")
        #expect(try tokenStore.load()?.accessToken == "fresh-access")
        #expect(try tokenStore.load()?.refreshToken == "fresh-refresh")
    }
}
