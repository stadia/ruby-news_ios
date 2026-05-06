//
//  NewsArticleRow.swift
//  ruby-news
//
//  Created by JEFF.DEAN on 5/7/26.
//

import SwiftUI

struct NewsArticleRow: View {
    let article: NewsArticle

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(article.displayTitle)
                .font(.headline)
                .foregroundStyle(.primary)

            if let summary = article.summary {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            HStack(spacing: 10) {
                if let host = article.host {
                    Label(host, systemImage: "globe")
                }

                Label("\(article.likersCount)", systemImage: "heart")
                Label("\(article.postsCount)", systemImage: "bubble")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !article.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(article.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.quaternary, in: Capsule())
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}
