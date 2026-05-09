//
//  FeedView.swift
//  ruby-news
//

import SwiftUI

struct FeedView: View {
    @State private var sessionStore = SessionStore()

    var body: some View {
        Group {
            if sessionStore.isLoading {
                ProgressView("로딩 중...")
            } else if sessionStore.isSignedIn {
                HotwireScreen(route: .feed)
                    .ignoresSafeArea(edges: .bottom)
            } else {
                signedOutView
            }
        }
        .onAppear {
            sessionStore.restoreSession()
            Task { @MainActor in
                await sessionStore.refresh()
            }
        }
    }

    private var signedOutView: some View {
        NavigationStack {
            SignedOutView(sessionStore: sessionStore)
                .navigationTitle("피드")
        }
    }
}

#Preview {
    FeedView()
}
