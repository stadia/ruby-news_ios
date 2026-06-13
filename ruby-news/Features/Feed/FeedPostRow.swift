import SwiftUI

struct FeedPostRow: View {
    let post: FeedPost
    var onSelected: () -> Void
    var onLikeTapped: () -> Void
    var onBoostTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 10) {
                if let boostedBy = post.boostedBy {
                    Label("@\(boostedBy) 님이 부스트함", systemImage: "arrow.2.squarepath")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(alignment: .firstTextBaseline) {
                    Text(post.authorName ?? "익명")
                        .font(.subheadline.weight(.semibold))

                    if let authorHost = post.authorHost {
                        Text(authorHost)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if let createdAt = post.createdAt {
                        Text(createdAt, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(post.displayBody)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if let contextLabel {
                    Label(contextLabel, systemImage: contextSystemImage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onSelected)

            HStack(spacing: 20) {
                Button(action: onLikeTapped) {
                    Label(
                        "\(post.likesCount)",
                        systemImage: post.liked ? "heart.fill" : "heart"
                    )
                    .foregroundStyle(post.liked ? .red : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(!post.isInteractive)
                .accessibilityLabel(
                    post.liked
                        ? "좋아요 취소, 현재 \(post.likesCount)개"
                        : "좋아요, 현재 \(post.likesCount)개"
                )

                Button(action: onBoostTapped) {
                    Label("\(post.boostsCount)", systemImage: "arrow.2.squarepath")
                        .foregroundStyle(post.boosted ? Color.rnBrand : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(!post.isInteractive)
                .accessibilityLabel(
                    post.boosted
                        ? "부스트 취소, 현재 \(post.boostsCount)개"
                        : "부스트, 현재 \(post.boostsCount)개"
                )

                Spacer()

                if post.isInteractive {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
            }
            .font(.caption)
        }
        .padding(.vertical, 8)
    }

    private var contextLabel: String? {
        if post.articleSlug != nil {
            return "기사 댓글"
        }
        if post.parentSlug != nil {
            return "답글"
        }
        if post.postType == .blog {
            return "블로그"
        }
        return nil
    }

    private var contextSystemImage: String {
        switch post.postType {
        case .blog:
            return "doc.text"
        case .comment:
            return "bubble.left"
        case .short:
            return "arrowshape.turn.up.left"
        }
    }
}
