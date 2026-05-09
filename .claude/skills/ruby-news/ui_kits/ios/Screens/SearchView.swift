// SearchView.swift — 검색.
// HIG `.searchable` modifier on a NavigationStack; results render as ArticleCard.

import SwiftUI

struct SearchView: View {
    @State private var query: String = ""
    @State private var allArticles: [Article] = MockArticles.all

    var results: [Article] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let q = query.lowercased()
        return allArticles.filter { a in
            a.titleKo.lowercased().contains(q) ||
            (a.titleEn?.lowercased().contains(q) ?? false) ||
            a.host.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RNColor.bgApp.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: RNSpacing.md) {
                        if query.isEmpty {
                            emptyState
                        } else if results.isEmpty {
                            noResults
                        } else {
                            ForEach(results) { a in
                                NavigationLink(value: a) { ArticleCard(article: a) }
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(RNSpacing.md)
                }
                .scrollContentBackground(.hidden)
                .navigationDestination(for: Article.self) { ArticleDetailView(article: $0) }
            }
            .navigationTitle("검색")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $query, prompt: "검색...")
        }
    }

    private var emptyState: some View {
        VStack(spacing: RNSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(RNColor.textContentMuted)
            Text("기사 제목, 출처, 키워드로 검색해 보세요")
                .font(.system(size: 14))
                .foregroundStyle(RNColor.textContentMuted)
                .multilineTextAlignment(.center)
            HStack(spacing: 6) {
                ForEach(["rails", "hotwire", "phlex", "pgvector"], id: \.self) { tag in
                    Button { query = tag } label: { RNBadge(text: "#\(tag)", tone: .neutral) }
                        .buttonStyle(.plain)
                }
            }
        }
        .padding(RNSpacing.xl)
    }

    private var noResults: some View {
        VStack(spacing: RNSpacing.sm) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(RNColor.textContentMuted)
            Text("검색 결과가 없습니다")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(RNColor.textContentSecondary)
            Text("\"\(query)\"에 해당하는 기사를 찾지 못했어요.")
                .font(.system(size: 13))
                .foregroundStyle(RNColor.textContentMuted)
        }
        .padding(RNSpacing.xl)
    }
}

// MARK: - Past articles (지난 글)

struct PastArticlesView: View {
    @State private var articles: [Article] = MockArticles.all

    var body: some View {
        NavigationStack {
            ZStack {
                RNColor.bgApp.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: RNSpacing.md) {
                        ForEach(articles) { a in
                            NavigationLink(value: a) { ArticleCard(article: a) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(RNSpacing.md)
                }
                .scrollContentBackground(.hidden)
                .refreshable { /* paginate older */ }
                .navigationDestination(for: Article.self) { ArticleDetailView(article: $0) }
            }
            .navigationTitle("지난 글")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
