//
//  AuthModelTests.swift
//  ruby-newsTests
//

import Foundation
import Testing
@testable import ruby_news

@Suite(.serialized)
struct AuthModelTests {
    // MARK: - CurrentUser / AccountResponse

    @Test func currentUserDecodesServerAccountResponse() async throws {
        let json = """
        {
          "user": {
            "id": 1,
            "email": "jeff@example.com",
            "name": "Jeff Dean",
            "username": "jeff",
            "avatar_url": "https://ruby-news.dev/rails/active_storage/blobs/redirect/abc123/avatar.jpeg"
          }
        }
        """

        let response = try APIClient.decoder.decode(AccountResponse.self, from: Data(json.utf8))
        let user = response.user

        #expect(user.id == 1)
        #expect(user.email == "jeff@example.com")
        #expect(user.name == "Jeff Dean")
        #expect(user.username == "jeff")
        #expect(user.avatarURL?.absoluteString == "https://ruby-news.dev/rails/active_storage/blobs/redirect/abc123/avatar.jpeg")
    }

    @Test func currentUserDecodesWithoutAvatar() async throws {
        let json = """
        {
          "user": {
            "id": 2,
            "email": "noavatar@example.com",
            "name": "No Avatar",
            "username": "noavatar",
            "avatar_url": null
          }
        }
        """

        let response = try APIClient.decoder.decode(AccountResponse.self, from: Data(json.utf8))
        #expect(response.user.avatarURL == nil)
        #expect(response.user.username == "noavatar")
        #expect(response.auth == nil)
    }

    @Test func accountResponseDecodesWithAuth() async throws {
        let json = """
        {
          "user": {
            "id": 1,
            "email": "jeff@example.com",
            "name": "Jeff",
            "username": "jeff",
            "avatar_url": null
          },
          "auth": {
            "access_token": "jwt-access",
            "refresh_token": "raw-refresh",
            "expires_in": 900
          }
        }
        """

        let response = try APIClient.decoder.decode(AccountResponse.self, from: Data(json.utf8))
        #expect(response.auth != nil)
        #expect(response.auth?.accessToken == "jwt-access")
        #expect(response.auth?.refreshToken == "raw-refresh")
        #expect(response.auth?.expiresIn == 900)

        let session = response.auth!.toAuthSession()
        #expect(session.accessToken == "jwt-access")
        #expect(session.refreshToken == "raw-refresh")
        #expect(!session.isExpired)
    }

    // MARK: - AuthSession

    @Test func authSessionParsesBearerHeader() async throws {
        let session = AuthSession(authorizationHeader: "Bearer eyJhbGciOiJIUzI1NiJ9.test")

        #expect(session != nil)
        #expect(session?.accessToken == "eyJhbGciOiJIUzI1NiJ9.test")
        #expect(session?.refreshToken == nil)
    }

    @Test func authSessionReturnsNilForMissingHeader() async {
        let session = AuthSession(authorizationHeader: nil)
        #expect(session == nil)
    }

    @Test func authSessionReturnsNilForNonBearerHeader() async {
        let session = AuthSession(authorizationHeader: "Basic abc123")
        #expect(session == nil)
    }

    @Test func authSessionReturnsNilForBearerWithEmptyToken() async {
        let session = AuthSession(authorizationHeader: "Bearer ")
        #expect(session == nil)
    }

    @Test func authSessionStoresRefreshToken() async throws {
        let session = AuthSession(
            authorizationHeader: "Bearer access-token",
            refreshToken: "raw-refresh-token"
        )

        #expect(session?.refreshToken == "raw-refresh-token")
    }

    @Test func authSessionCalculatesExpiresAt() async throws {
        let before = Date()
        let session = AuthSession(authorizationHeader: "Bearer token", expiresIn: 900)
        let after = Date()

        let expiresAt = try #require(session?.expiresAt)
        #expect(expiresAt >= before.addingTimeInterval(900))
        #expect(expiresAt <= after.addingTimeInterval(900))
    }

    @Test func authSessionDetectsExpiration() async throws {
        let expired = AuthSession(
            accessToken: "token",
            expiresAt: Date().addingTimeInterval(-1)
        )
        let valid = AuthSession(
            accessToken: "token",
            expiresAt: Date().addingTimeInterval(900)
        )

        #expect(expired.isExpired)
        #expect(!valid.isExpired)
    }

    @Test func refreshTokenResponseDecodes() async throws {
        let json = """
        {
          "access_token": "new-access",
          "refresh_token": "new-refresh",
          "expires_in": 900
        }
        """

        let response = try APIClient.decoder.decode(RefreshTokenResponse.self, from: Data(json.utf8))
        #expect(response.accessToken == "new-access")
        #expect(response.refreshToken == "new-refresh")
        #expect(response.expiresIn == 900)

        let session = response.toAuthSession()
        #expect(session.accessToken == "new-access")
        #expect(session.refreshToken == "new-refresh")
        #expect(!session.isExpired)
    }

    // MARK: - TokenStore

    @Test func inMemoryTokenStoreSavesAndLoads() async throws {
        let store = InMemoryTokenStore()
        #expect(try store.load() == nil)

        let session = AuthSession(
            accessToken: "access",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(900)
        )
        try store.save(session)

        let loaded = try #require(try store.load())
        #expect(loaded.accessToken == "access")
        #expect(loaded.refreshToken == "refresh")
    }

    @Test func inMemoryTokenStoreDeleteClearsSession() async throws {
        let store = InMemoryTokenStore()
        let session = AuthSession(
            accessToken: "access",
            expiresAt: Date().addingTimeInterval(900)
        )
        try store.save(session)
        #expect(try store.load() != nil)

        try store.delete()
        #expect(try store.load() == nil)
    }

    @Test func inMemoryTokenStoreSaveOverwritesPrevious() async throws {
        let store = InMemoryTokenStore()
        let first = AuthSession(
            accessToken: "first",
            expiresAt: Date().addingTimeInterval(900)
        )
        let second = AuthSession(
            accessToken: "second",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(900)
        )

        try store.save(first)
        try store.save(second)

        let loaded = try #require(try store.load())
        #expect(loaded.accessToken == "second")
        #expect(loaded.refreshToken == "refresh")
    }
}
