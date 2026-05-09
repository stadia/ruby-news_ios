//
//  ContentView.swift
//  ruby-news
//
//  Created by JEFF.DEAN on 5/6/26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .news

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.news.title, systemImage: AppTab.news.systemImage, value: .news) {
                NewsView()
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
                NewsView(title: AppTab.search.title, showsSearch: true, presentsSearchOnAppear: true)
                    .accessibilityIdentifier(AppTab.search.accessibilityIdentifier)
            }
        }
    }
}

#Preview {
    ContentView()
}
