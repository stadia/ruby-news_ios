// FeedView.swift — 홈 / 기사 피드.
// HIG-native NavigationStack + List, Ruby-News tokens applied via .listRowBackground / .scrollContentBackground.
// Pull-to-refresh uses the system spinner (`.refreshable`) — tinted by the global brand accent.

import SwiftUI

struct FeedView: View {
    @State private var articles: [Article] = MockArticles.all
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                RNColor.bgApp.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: RNSpacing.md) {
                        // Page header — Korean h1 + lede.
                        VStack(alignment: .leading, spacing: 4) {
                            Text("오늘의 Ruby · Rails 뉴스")
                                .font(RNFont.xl3)
                                .foregroundStyle(RNColor.textContent)
                            Text("최신 Ruby, Rails 관련 뉴스와 트렌드를 한곳에서 만나보세요")
                                .font(RNFont.sm)
                                .foregroundStyle(RNColor.textContentMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, RNSpacing.sm)

                        ForEach(articles) { a in
                            NavigationLink(value: a) {
                                ArticleCard(article: a, liked: a.id == 3)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, RNSpacing.md)
                    .padding(.bottom, RNSpacing.xl)
                }
                .scrollContentBackground(.hidden)
                .refreshable { await refresh() }      // pull-to-refresh
                .navigationDestination(for: Article.self) { a in
                    ArticleDetailView(article: a)
                }
            }
            // Brand 4-px top accent under the nav bar.
            .safeAreaInset(edge: .top, spacing: 0) {
                Rectangle().fill(RNColor.brand).frame(height: 4)
            }
            .navigationTitle("Ruby-News")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RNColor.bgApp, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    @MainActor
    private func refresh() async {
        // Stub — wire up to the real /articles endpoint.
        try? await Task.sleep(nanoseconds: 700_000_000)
        articles = MockArticles.all.shuffled()
    }
}
