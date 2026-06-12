//
//  NewsArticleRow.swift
//  ruby-news
//
//  Created by JEFF.DEAN on 5/7/26.
//

import SwiftUI

struct NewsArticleRow: View {
    let article: NewsArticle
    var onTagSelected: ((String) -> Void)?
    var onLikeTapped: (() -> Void)?
    var onBoostTapped: (() -> Void)?

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
                        .accessibilityLabel("출처 \(host)")
                }

                Button {
                    onLikeTapped?()
                } label: {
                    Label(
                        "\(article.likersCount)",
                        systemImage: article.liked ? "heart.fill" : "heart"
                    )
                    .foregroundStyle(article.liked ? .red : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(article.liked ? "좋아요 취소, 현재 \(article.likersCount)개" : "좋아요, 현재 \(article.likersCount)개")

                Button {
                    onBoostTapped?()
                } label: {
                    Label("\(article.boostsCount)", systemImage: "arrow.2.squarepath")
                        .foregroundStyle(article.boosted ? Color.rnBrand : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    article.boosted
                        ? "부스트 취소, 현재 \(article.boostsCount)개"
                        : "부스트, 현재 \(article.boostsCount)개"
                )

                Label("\(article.postsCount)", systemImage: "bubble")
                    .accessibilityLabel("댓글 \(article.postsCount)개")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !article.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(article.tags, id: \.self) { tag in
                            Button {
                                onTagSelected?(tag)
                            } label: {
                                Text("#\(tag)")
                                    .font(.caption2)
                                    .foregroundStyle(Color.rnBrand)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.quaternary, in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .disabled(onTagSelected == nil)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}
