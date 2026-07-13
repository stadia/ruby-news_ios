//
//  NewsView.swift
//  ruby-news
//
//  Created by JEFF.DEAN on 5/6/26.
//

import SwiftUI

struct NewsView: View {
    @State private var sourcePageIndex: Int = 0

    private let title: String
    private let showsSearch: Bool
    private let presentsSearchOnAppear: Bool
    private let onArticleSelected: (String) -> Void

    init(
        title: String = "뉴스",
        showsSearch: Bool = false,
        presentsSearchOnAppear: Bool = false,
        onArticleSelected: @escaping (String) -> Void = { _ in }
    ) {
        self.title = title
        self.showsSearch = showsSearch
        self.presentsSearchOnAppear = presentsSearchOnAppear
        self.onArticleSelected = onArticleSelected
    }

    var body: some View {
        if showsSearch {
            NewsSearchPage(
                title: title,
                presentsSearchOnAppear: presentsSearchOnAppear,
                onArticleSelected: onArticleSelected
            )
        } else {
            NavigationStack {
                TabView(selection: $sourcePageIndex) {
                    ForEach(Array(NewsSource.allCases.enumerated()), id: \.element) {
                        index, source in
                        NewsSourcePage(source: source, onArticleSelected: onArticleSelected)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .navigationTitle(navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private var navigationTitle: String {
        "\(title) (\(currentSourceLabel))"
    }

    private var currentSourceLabel: String {
        let sources = NewsSource.allCases
        guard sourcePageIndex >= 0, sourcePageIndex < sources.count else { return "" }
        return sources[sourcePageIndex].label
    }
}

#Preview {
    NewsView()
}
