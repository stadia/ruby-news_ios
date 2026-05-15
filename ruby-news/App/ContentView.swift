//
//  ContentView.swift
//  ruby-news
//
//  Created by JEFF.DEAN on 5/6/26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .news
    @State private var selectedArticle: ArticleRoute?
    @State private var sessionStore = SessionStore()

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.news.title, systemImage: AppTab.news.systemImage, value: .news) {
                NewsView(onArticleSelected: presentArticle)
                    .accessibilityIdentifier(AppTab.news.accessibilityIdentifier)
            }

            Tab(AppTab.feed.title, systemImage: AppTab.feed.systemImage, value: .feed) {
                FeedView()
                    .accessibilityIdentifier(AppTab.feed.accessibilityIdentifier)
            }

            Tab(AppTab.profile.title, systemImage: AppTab.profile.systemImage, value: .profile) {
                ProfileView()
                    .accessibilityIdentifier(AppTab.profile.accessibilityIdentifier)
            }

            Tab(value: AppTab.search, role: .search) {
                NewsView(
                    title: AppTab.search.title,
                    showsSearch: true,
                    presentsSearchOnAppear: true,
                    onArticleSelected: presentArticle
                )
                    .accessibilityIdentifier(AppTab.search.accessibilityIdentifier)
            }
        }
        .sheet(item: $selectedArticle) { route in
            HotwireScreen(route: .article(id: route.id))
                .ignoresSafeArea(edges: .bottom)
        }
        .environment(sessionStore)
        .task {
            sessionStore.restoreSession()
            await sessionStore.refresh()
        }
    }

    private func presentArticle(id: String) {
        selectedArticle = ArticleRoute(id: id)
    }
}

private struct ArticleRoute: Identifiable {
    let id: String
}

#Preview {
    ContentView()
}
