//
//  APIClientTests.swift
//  ruby-newsTests
//

import Foundation
import Mocker
import Testing
@testable import ruby_news

@Suite(.serialized)
struct APIClientTests {
    /// Mocker 도입 데모. 고정 응답 케이스는 Mocker를 우선 사용한다.
    @Test func logoutWithMockerReturnsSuccessfully() async throws {
        let auth = AuthSession(accessToken: "jwt-token", refreshToken: "refresh", expiresAt: Date().addingTimeInterval(900))
        let url = try #require(URL(string: "http://localhost:3000/logout"))
        var mock = Mock(url: url, contentType: .json, statusCode: 204, data: [.get: Data()])
        mock.register()
        defer { Mocker.removeAll() }

        let client = APIClient(session: URLSession.mockerSession(), tokenProvider: { auth })
        try await client.logout()
    }

    @Test func loginDecodesResponse() async throws {
        let loginBody = """
        {
          "user": {
            "id": 1,
            "email": "jeff@example.com",
            "name": "Jeff",
            "username": "jeff",
            "avatar_url": null,
            "created_at": "2026-05-08T17:30:01.391+09:00",
            "updated_at": "2026-05-08T17:30:01.391+09:00"
          },
          "refresh_token": "raw-refresh-token"
        }
        """
        let loginURL = try #require(URL(string: "http://localhost:3000/login"))
        let mockResponse = HTTPURLResponse(url: loginURL, statusCode: 200, httpVersion: nil,
            headerFields: ["Content-Type": "application/json", "Authorization": "Bearer access-token"])!

        let session = URLSession.mockSession { request in
            #expect(request.url?.absoluteString == "http://localhost:3000/login")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            guard let body = TestHelpers.requestBodyData(from: request),
                  let payload = try? JSONSerialization.jsonObject(with: body) as? [String: [String: String]] else {
                Issue.record("Expected JSON login request body")
                return (mockResponse, Data(loginBody.utf8))
            }
            #expect(payload["user"]?["email"] == "jeff@example.com")
            #expect(payload["user"]?["password"] == "password")

            return (mockResponse, Data(loginBody.utf8))
        }
        let client = APIClient(session: session)

        let result = try await client.login(email: "jeff@example.com", password: "password")
        #expect(result.user.id == 1)
        #expect(result.user.email == "jeff@example.com")
        #expect(result.user.username == "jeff")
        #expect(result.auth.accessToken == "access-token")
        #expect(result.auth.refreshToken == "raw-refresh-token")
    }

    @Test func loginUsesServerProvidedExpiresIn() async throws {
        let loginBody = """
        {
          "user": {
            "id": 1,
            "email": "jeff@example.com",
            "name": "Jeff",
            "username": "jeff",
            "avatar_url": null
          },
          "refresh_token": "raw-refresh-token",
          "expires_in": 60
        }
        """
        let session = URLSession.mockSession { request in
            (
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Authorization": "Bearer access-token"])!,
                Data(loginBody.utf8)
            )
        }
        let client = APIClient(session: session)

        let before = Date()
        let result = try await client.login(email: "jeff@example.com", password: "password")
        let after = Date()

        #expect(result.auth.expiresAt >= before.addingTimeInterval(60))
        #expect(result.auth.expiresAt <= after.addingTimeInterval(60))
    }

    @Test func loginFallsBackToDefaultExpiresInWhenAbsent() async throws {
        let loginBody = """
        {
          "user": {
            "id": 1,
            "email": "jeff@example.com",
            "name": "Jeff",
            "username": "jeff",
            "avatar_url": null
          },
          "refresh_token": "raw-refresh-token"
        }
        """
        let session = URLSession.mockSession { request in
            (
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Authorization": "Bearer access-token"])!,
                Data(loginBody.utf8)
            )
        }
        let client = APIClient(session: session)

        let before = Date()
        let result = try await client.login(email: "jeff@example.com", password: "password")
        let after = Date()

        #expect(result.auth.expiresAt >= before.addingTimeInterval(900))
        #expect(result.auth.expiresAt <= after.addingTimeInterval(900))
    }

    @Test func loginThrowsMissingAccessTokenWhenAuthorizationHeaderMissing() async {
        let session = URLSession.mockSession { request in
            (
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                Data("{\"user\":{\"id\":1,\"email\":\"jeff@example.com\",\"name\":\"Jeff\",\"username\":\"jeff\",\"avatar_url\":null},\"refresh_token\":\"refresh\"}".utf8)
            )
        }
        let client = APIClient(session: session)

        do {
            _ = try await client.login(email: "jeff@example.com", password: "password")
            Issue.record("Expected missing access token error")
        } catch APIError.missingAccessToken {
            // expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func loginThrowsOn401() async {
        let session = URLSession.mockSession { request in
            (
                HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                Data("{\"error\":\"unauthorized\"}".utf8)
            )
        }
        let client = APIClient(session: session)

        do {
            _ = try await client.login(email: "wrong@example.com", password: "wrong")
            Issue.record("Expected login to throw")
        } catch APIError.unacceptableStatusCode(401) {
            // expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func logoutUsesBearerTokenAndAcceptHeader() async throws {
        let auth = AuthSession(accessToken: "jwt-token", refreshToken: "refresh", expiresAt: Date().addingTimeInterval(900))
        let session = URLSession.mockSession { request in
            #expect(request.url?.absoluteString == "http://localhost:3000/logout")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer jwt-token")
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
            return (
                HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                nil
            )
        }
        let client = APIClient(session: session, tokenProvider: { auth })

        try await client.logout()
    }

    @Test func likeSendsBearerTokenAndDecodesResponse() async throws {
        let auth = AuthSession(accessToken: "jwt-token", refreshToken: "refresh", expiresAt: Date().addingTimeInterval(900))
        let responseBody = """
        {
          "likeable_type": "Article",
          "likeable_slug": "rails-8-1",
          "liked": true,
          "likes_count": 13
        }
        """
        let session = URLSession.mockSession { request in
            #expect(request.url?.absoluteString == "http://localhost:3000/api/v1/articles/rails-8-1/like")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer jwt-token")
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            guard let body = TestHelpers.requestBodyData(from: request),
                  let payload = try? JSONSerialization.jsonObject(with: body) as? [String: String] else {
                Issue.record("Expected JSON like request body")
                return (
                    HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                    Data(responseBody.utf8)
                )
            }
            #expect(payload["likeable_type"] == "Article")

            return (
                HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                Data(responseBody.utf8)
            )
        }
        let client = APIClient(session: session, tokenProvider: { auth })

        let response = try await client.like(articleSlug: "rails-8-1")
        #expect(response.liked)
        #expect(response.likesCount == 13)
        #expect(response.likeableSlug == "rails-8-1")
    }

    @Test func unlikeSendsDeleteAndDecodesResponse() async throws {
        let auth = AuthSession(accessToken: "jwt-token", refreshToken: "refresh", expiresAt: Date().addingTimeInterval(900))
        let responseBody = """
        {
          "likeable_type": "Article",
          "likeable_slug": "rails-8-1",
          "liked": false,
          "likes_count": 12
        }
        """
        let session = URLSession.mockSession { request in
            #expect(request.url?.absoluteString == "http://localhost:3000/api/v1/articles/rails-8-1/like")
            #expect(request.httpMethod == "DELETE")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer jwt-token")
            return (
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                Data(responseBody.utf8)
            )
        }
        let client = APIClient(session: session, tokenProvider: { auth })

        let response = try await client.unlike(articleSlug: "rails-8-1")
        #expect(!response.liked)
        #expect(response.likesCount == 12)
    }

    @Test func likeRefreshesTokenAndRetriesAfterUnauthorized() async throws {
        let staleAuth = AuthSession(accessToken: "stale-access", refreshToken: "refresh-token", expiresAt: Date().addingTimeInterval(-60))
        let refreshedAuth = AuthSession(accessToken: "fresh-access", refreshToken: "fresh-refresh", expiresAt: Date().addingTimeInterval(900))
        let authBox = LockedBox(staleAuth)
        let didPersistRefreshedToken = LockedBox(false)
        var recordedAuthHeaders: [String?] = []

        let session = URLSession.mockSession { request in
            let path = request.url?.path

            switch path {
            case "/api/v1/articles/rails-8-1/like":
                recordedAuthHeaders.append(request.value(forHTTPHeaderField: "Authorization"))
                let statusCode = recordedAuthHeaders.count == 1 ? 401 : 201
                let body = recordedAuthHeaders.count == 1
                    ? Data("{\"error\":\"unauthorized\"}".utf8)
                    : Data("{\"likeable_type\":\"Article\",\"likeable_slug\":\"rails-8-1\",\"liked\":true,\"likes_count\":13}".utf8)
                return (
                    HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                    body
                )
            case "/api/v1/auth/refresh":
                #expect(request.httpMethod == "POST")
                #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
                #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

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

        var client = APIClient(session: session, tokenProvider: { authBox.value })
        client.onTokenRefreshed = { session in
            authBox.value = session
            didPersistRefreshedToken.value = true
        }

        let response = try await client.like(articleSlug: "rails-8-1")

        #expect(response.liked)
        #expect(response.likesCount == 13)
        #expect(recordedAuthHeaders == ["Bearer stale-access", "Bearer fresh-access"])
        #expect(didPersistRefreshedToken.value)
        #expect(authBox.value.accessToken == refreshedAuth.accessToken)
        #expect(authBox.value.refreshToken == refreshedAuth.refreshToken)
    }

    @Test func boostSendsBearerTokenAndDecodesResponse() async throws {
        let auth = AuthSession(accessToken: "jwt-token", refreshToken: "refresh", expiresAt: Date().addingTimeInterval(900))
        let responseBody = """
        {
          "boostable_type": "Article",
          "boostable_slug": "rails-8-1",
          "boosted": true,
          "boosts_count": 4
        }
        """
        let session = URLSession.mockSession { request in
            #expect(request.url?.absoluteString == "http://localhost:3000/api/v1/articles/rails-8-1/boost")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer jwt-token")
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            guard let body = TestHelpers.requestBodyData(from: request),
                  let payload = try? JSONSerialization.jsonObject(with: body) as? [String: String] else {
                Issue.record("Expected JSON boost request body")
                return (
                    HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!,
                    Data(responseBody.utf8)
                )
            }
            #expect(payload["boostable_type"] == "Article")

            return (
                HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!,
                Data(responseBody.utf8)
            )
        }
        let client = APIClient(session: session, tokenProvider: { auth })

        let response = try await client.boost(articleSlug: "rails-8-1")
        #expect(response.boosted)
        #expect(response.boostsCount == 4)
        #expect(response.boostableSlug == "rails-8-1")
    }

    @Test func unboostSendsDeleteAndDecodesResponse() async throws {
        let auth = AuthSession(accessToken: "jwt-token", refreshToken: "refresh", expiresAt: Date().addingTimeInterval(900))
        let responseBody = """
        {
          "boostable_type": "Article",
          "boostable_slug": "rails-8-1",
          "boosted": false,
          "boosts_count": 3
        }
        """
        let session = URLSession.mockSession { request in
            #expect(request.url?.absoluteString == "http://localhost:3000/api/v1/articles/rails-8-1/boost")
            #expect(request.httpMethod == "DELETE")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer jwt-token")
            return (
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                Data(responseBody.utf8)
            )
        }
        let client = APIClient(session: session, tokenProvider: { auth })

        let response = try await client.unboost(articleSlug: "rails-8-1")
        #expect(!response.boosted)
        #expect(response.boostsCount == 3)
    }

    @Test func boostRefreshesTokenAndRetriesAfterUnauthorized() async throws {
        let staleAuth = AuthSession(accessToken: "stale-access", refreshToken: "refresh-token", expiresAt: Date().addingTimeInterval(-60))
        let authBox = LockedBox(staleAuth)
        var recordedAuthHeaders: [String?] = []

        let session = URLSession.mockSession { request in
            switch request.url?.path {
            case "/api/v1/articles/rails-8-1/boost":
                recordedAuthHeaders.append(request.value(forHTTPHeaderField: "Authorization"))
                let isRetry = recordedAuthHeaders.count == 2
                let statusCode = isRetry ? 201 : 401
                let body = isRetry
                    ? Data("{\"boostable_type\":\"Article\",\"boostable_slug\":\"rails-8-1\",\"boosted\":true,\"boosts_count\":4}".utf8)
                    : Data("{\"error\":\"unauthorized\"}".utf8)
                return (HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!, body)
            case "/api/v1/auth/refresh":
                return (
                    HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                    Data("{\"access_token\":\"fresh-access\",\"refresh_token\":\"fresh-refresh\",\"expires_in\":900}".utf8)
                )
            default:
                Issue.record("Unexpected path: \(request.url?.path ?? "nil")")
                return (HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!, nil)
            }
        }

        var client = APIClient(session: session, tokenProvider: { authBox.value })
        client.onTokenRefreshed = { authBox.value = $0 }

        let response = try await client.boost(articleSlug: "rails-8-1")

        #expect(response.boosted)
        #expect(recordedAuthHeaders == ["Bearer stale-access", "Bearer fresh-access"])
        #expect(authBox.value.accessToken == "fresh-access")
    }

    @Test func feedSendsPageAndBearerTokenAndDecodesResponse() async throws {
        let auth = AuthSession(
            accessToken: "jwt-token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(900)
        )
        let responseBody = """
        {
          "posts": [{
            "id": 42,
            "slug": "native-feed-post",
            "body": "Native Feed",
            "post_type": "short",
            "status": "published",
            "created_at": "2026-06-13 00:30:00 +0900",
            "updated_at": "2026-06-13 00:31:00 +0900",
            "likes_count": 3,
            "boosts_count": 2,
            "liked": true,
            "boosted": false
          }],
          "pagination": {"next_page": 3, "limit": 20}
        }
        """
        let session = URLSession.mockSession { request in
            #expect(request.url?.absoluteString == "http://localhost:3000/feed?page=2")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer jwt-token")
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
            return (
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!,
                Data(responseBody.utf8)
            )
        }
        let client = APIClient(session: session, tokenProvider: { auth })

        let response = try await client.feed(page: "2")

        #expect(response.posts.map(\.id) == [42])
        #expect(response.pagination.nextPage == "3")
    }

    @Test func feedRefreshesTokenAndRetriesAfterUnauthorized() async throws {
        let authBox = LockedBox(AuthSession(
            accessToken: "stale-access",
            refreshToken: "refresh-token",
            expiresAt: Date().addingTimeInterval(-60)
        ))
        var feedHeaders: [String?] = []
        let session = URLSession.mockSession { request in
            switch request.url?.path {
            case "/feed":
                feedHeaders.append(request.value(forHTTPHeaderField: "Authorization"))
                let isRetry = feedHeaders.count == 2
                return (
                    HTTPURLResponse(
                        url: request.url!,
                        statusCode: isRetry ? 200 : 401,
                        httpVersion: nil,
                        headerFields: nil
                    )!,
                    isRetry
                        ? Data(#"{"posts":[],"pagination":{"next_page":null,"limit":20}}"#.utf8)
                        : Data(#"{"error":"unauthorized"}"#.utf8)
                )
            case "/api/v1/auth/refresh":
                return (
                    HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                    Data(#"{"access_token":"fresh-access","refresh_token":"fresh-refresh","expires_in":900}"#.utf8)
                )
            default:
                Issue.record("Unexpected path: \(request.url?.path ?? "nil")")
                return (
                    HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!,
                    nil
                )
            }
        }
        var client = APIClient(session: session, tokenProvider: { authBox.value })
        client.onTokenRefreshed = { authBox.value = $0 }

        _ = try await client.feed()

        #expect(feedHeaders == ["Bearer stale-access", "Bearer fresh-access"])
        #expect(authBox.value.accessToken == "fresh-access")
    }

    @Test func postLikeAndUnlikeUsePostV1Path() async throws {
        let auth = AuthSession(
            accessToken: "jwt-token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(900)
        )
        var methods: [String?] = []
        let session = URLSession.mockSession { request in
            #expect(request.url?.absoluteString == "http://localhost:3000/api/v1/posts/post-42/like")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer jwt-token")
            if let body = TestHelpers.requestBodyData(from: request),
               let payload = try? JSONSerialization.jsonObject(with: body) as? [String: String] {
                #expect(payload["likeable_type"] == "Post")
            } else {
                Issue.record("Expected post like request body")
            }
            methods.append(request.httpMethod)
            return (
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: request.httpMethod == "POST" ? 201 : 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data("""
                {
                  "likeable_type": "Post",
                  "likeable_slug": "post-42",
                  "liked": \(request.httpMethod == "POST"),
                  "likes_count": \(request.httpMethod == "POST" ? 4 : 3)
                }
                """.utf8)
            )
        }
        let client = APIClient(session: session, tokenProvider: { auth })

        let liked = try await client.like(postSlug: "post-42")
        let unliked = try await client.unlike(postSlug: "post-42")

        #expect(liked.liked)
        #expect(liked.likesCount == 4)
        #expect(!unliked.liked)
        #expect(unliked.likesCount == 3)
        #expect(methods == ["POST", "DELETE"])
    }

    @Test func postBoostAndUnboostUsePostV1Path() async throws {
        let auth = AuthSession(
            accessToken: "jwt-token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(900)
        )
        var methods: [String?] = []
        let session = URLSession.mockSession { request in
            #expect(request.url?.absoluteString == "http://localhost:3000/api/v1/posts/post-42/boost")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer jwt-token")
            if let body = TestHelpers.requestBodyData(from: request),
               let payload = try? JSONSerialization.jsonObject(with: body) as? [String: String] {
                #expect(payload["boostable_type"] == "Post")
            } else {
                Issue.record("Expected post boost request body")
            }
            methods.append(request.httpMethod)
            return (
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: request.httpMethod == "POST" ? 201 : 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                Data("""
                {
                  "boostable_type": "Post",
                  "boostable_slug": "post-42",
                  "boosted": \(request.httpMethod == "POST"),
                  "boosts_count": \(request.httpMethod == "POST" ? 3 : 2)
                }
                """.utf8)
            )
        }
        let client = APIClient(session: session, tokenProvider: { auth })

        let boosted = try await client.boost(postSlug: "post-42")
        let unboosted = try await client.unboost(postSlug: "post-42")

        #expect(boosted.boosted)
        #expect(boosted.boostsCount == 3)
        #expect(!unboosted.boosted)
        #expect(unboosted.boostsCount == 2)
        #expect(methods == ["POST", "DELETE"])
    }

    /// v1 공통 에러 포맷(`{ "error": "parameter_missing", "parameter": ... }`)이
    /// refresh 응답으로 와도, retry 경로가 호출자에게 `.unauthorized`를 전달해야 한다.
    @Test func refreshFailureWithV1ParameterMissingSurfacesAsUnauthorized() async throws {
        let staleAuth = AuthSession(accessToken: "stale", refreshToken: "stale-refresh", expiresAt: Date().addingTimeInterval(-60))
        let articlesURL = try #require(URL(string: "http://localhost:3000/api/v1/articles"))
        let refreshURL = try #require(URL(string: "http://localhost:3000/api/v1/auth/refresh"))

        var articlesMock = Mock(url: articlesURL, contentType: .json, statusCode: 401, data: [.get: Data("{}".utf8)])
        articlesMock.register()
        var refreshMock = Mock(
            url: refreshURL,
            contentType: .json,
            statusCode: 400,
            data: [.post: Data(#"{"error":"parameter_missing","parameter":"refresh_token"}"#.utf8)]
        )
        refreshMock.register()
        defer { Mocker.removeAll() }

        let client = APIClient(session: URLSession.mockerSession(), tokenProvider: { staleAuth })

        do {
            _ = try await client.articles()
            Issue.record("Expected APIError.unauthorized")
        } catch APIError.unauthorized {
            // expected
        } catch {
            Issue.record("Expected APIError.unauthorized, got \(error)")
        }
    }
}
