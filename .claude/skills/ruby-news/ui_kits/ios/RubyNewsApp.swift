// RubyNewsApp.swift
// App entry — TabView, dark by default with green accent.
// HIG-base + functional brand color (green ~150).
//
// NOTE: 실제 출시 앱은 3탭 (뉴스 / 피드 / 내 정보) 입니다. 아래 RootTabView 의 4-탭 예시는
// 키트 패턴 참조용이며 (홈/검색/지난 글/프로필 화면을 한 자리에서 보여주기 위함),
// 앱 구조의 정본은 SKILL.md "iOS app" 섹션을 따르세요.

import SwiftUI

@main
struct RubyNewsApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(.dark)        // dark-first; remove for system-driven
                .tint(RNColor.brand)                // global accent
                .background(RNColor.bgApp.ignoresSafeArea())
        }
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            FeedView()
                .tabItem { Label("홈", systemImage: "house") }

            SearchView()
                .tabItem { Label("검색", systemImage: "magnifyingglass") }

            PastArticlesView()
                .tabItem { Label("지난 글", systemImage: "newspaper") }

            ProfileView()
                .tabItem { Label("프로필", systemImage: "person.crop.circle") }
        }
        // Tint applied at app level; tab bar inherits it.
    }
}
