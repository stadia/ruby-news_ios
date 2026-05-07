//
//  SessionStore.swift
//  ruby-news
//

import Foundation
import Observation

@MainActor
@Observable
final class SessionStore {
    private let fetchCurrentUser: () async throws -> CurrentUser

    var currentUser: CurrentUser?
    var isLoading = false

    var isSignedIn: Bool { currentUser != nil }

    init(apiClient: APIClient = APIClient()) {
        self.fetchCurrentUser = { try await apiClient.me() }
    }

    init(fetchCurrentUser: @escaping () async throws -> CurrentUser) {
        self.fetchCurrentUser = fetchCurrentUser
    }

    func refresh() async {
        isLoading = true
        do {
            currentUser = try await fetchCurrentUser()
        } catch {
            currentUser = nil
        }
        isLoading = false
    }

    func clear() {
        currentUser = nil
    }
}