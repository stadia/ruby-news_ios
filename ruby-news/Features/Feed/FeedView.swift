//
//  FeedView.swift
//  ruby-news
//

import SwiftUI

struct FeedView: View {
    @Environment(SessionStore.self) private var sessionStore

    var body: some View {
        Group {
            if sessionStore.isLoading && !sessionStore.isSignedIn {
                ProgressView("로딩 중...")
            } else if sessionStore.isSignedIn {
                HotwireScreen(route: .feed)
                    .ignoresSafeArea(edges: .bottom)
            } else {
                NavigationStack {
                    SignedOutView()
                        .navigationTitle("피드")
                }
            }
        }
    }
}

#Preview {
    FeedView()
        .environment(SessionStore())
}
