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
            ForEach(AppTab.allCases) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                    .tag(tab)
                    .accessibilityIdentifier(tab.accessibilityIdentifier)
            }
        }
    }

    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        switch tab {
        case .news:
            NewsView()
        case .feed:
            FeedView()
        case .profile:
            ProfileView()
        }
    }
}

#Preview {
    ContentView()
}
