// RubyNewsComponents.swift
// Reusable SwiftUI components — composable analogues of Components.jsx.
// Korean copy is canonical; English mirrors only inside titles where the original article had one.

import SwiftUI

// MARK: - Button

struct RNButton: View {
    enum Variant { case primary, info, ghost, danger }
    enum Size { case sm, md, lg }

    let title: String
    var variant: Variant = .primary
    var size: Size = .md
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(font)
            .padding(.horizontal, hPad)
            .padding(.vertical, vPad)
            .frame(minHeight: 44)            // HIG hit-target floor
            .frame(maxWidth: .infinity)
            .foregroundStyle(fg)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: RNRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: RNRadius.md, style: .continuous)
                    .strokeBorder(border, lineWidth: variant == .ghost ? 1 : 0)
            )
        }
        .buttonStyle(.plain)
        .animation(RNMotion.base, value: variant)
    }

    // —— styling ——————————————————————————————————————————————————————————
    private var fg: Color {
        switch variant {
        case .primary, .danger: return RNColor.brandForeground
        case .info:             return RNColor.brandForeground
        case .ghost:            return RNColor.textContentSecondary
        }
    }
    private var bg: Color {
        switch variant {
        case .primary: return RNColor.brand
        case .info:    return RNColor.infoSolid
        case .danger:  return RNColor.dangerSolid
        case .ghost:   return .clear
        }
    }
    private var border: Color { RNColor.borderStrong }
    private var hPad: CGFloat { size == .sm ? 12 : size == .md ? 16 : 20 }
    private var vPad: CGFloat { size == .sm ? 6  : size == .md ? 10 : 12 }
    private var font: Font {
        size == .sm ? RNFont.sm : size == .md ? RNFont.bodyMedium(15) : RNFont.bodyBold(16)
    }
}

// MARK: - Badge

struct RNBadge: View {
    enum Tone { case neutral, blue, green }
    let text: String
    var tone: Tone = .neutral

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(bg, in: Capsule())
            .overlay(Capsule().strokeBorder(stroke, lineWidth: 1))
    }
    private var fg: Color { tone == .blue ? RNColor.infoText : tone == .green ? RNColor.brand : RNColor.textContentSecondary }
    private var bg: Color { fg.opacity(0.10) }
    private var stroke: Color { fg.opacity(0.20) }
}

// MARK: - Card

struct RNCard<Content: View>: View {
    var padding: CGFloat = RNSpacing.md
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(RNColor.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: RNRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: RNRadius.lg, style: .continuous)
                    .strokeBorder(RNColor.borderStrong, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Avatar

struct RNAvatar: View {
    let name: String
    var size: CGFloat = 36
    var tone: RNBadge.Tone = .green

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(RNColor.brandForeground)
            .frame(width: size, height: size)
            .background(bg)
            .clipShape(Circle())
    }
    private var initials: String {
        name.split(separator: " ").prefix(2)
            .compactMap { $0.first }.map(String.init).joined().uppercased()
    }
    private var bg: Color {
        switch tone {
        case .green:   return RNColor.brand
        case .blue:    return RNColor.infoSolid
        case .neutral: return RNColor.bgSurfaceMuted
        }
    }
}

// MARK: - Article model + card

struct Article: Identifiable, Hashable {
    let id: Int
    let titleKo: String
    let titleEn: String?
    let host: String
    let author: String
    let publishedAt: String
    let likes: Int
    let comments: Int
    let summaryKey: [String]
    let url: String
}

struct ArticleCard: View {
    let article: Article
    var liked: Bool = false

    var body: some View {
        RNCard {
            VStack(alignment: .leading, spacing: RNSpacing.sm) {
                Text(article.titleKo)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(RNColor.textContent)
                    .lineLimit(2)
                if let en = article.titleEn, en != article.titleKo {
                    Text(en)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(RNColor.textContentSecondary)
                        .lineLimit(2)
                }
                RNBadge(text: article.host, tone: .blue)
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(article.summaryKey.enumerated()), id: \.offset) { _, s in
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("•").foregroundStyle(RNColor.textContentMuted)
                            Text(s)
                                .font(.system(size: 13))
                                .foregroundStyle(RNColor.textContentSecondary)
                        }
                    }
                }
                .padding(.top, RNSpacing.xs)

                Divider().background(RNColor.borderSubtle)

                HStack(spacing: 12) {
                    Label(article.author, systemImage: "person")
                    Label("\(article.likes)", systemImage: liked ? "heart.fill" : "heart")
                        .foregroundStyle(liked ? RNColor.dangerText : RNColor.textContentMuted)
                    Label("\(article.comments)", systemImage: "bubble.left")
                    Spacer()
                    Label(article.publishedAt, systemImage: "calendar")
                }
                .font(.system(size: 11))
                .foregroundStyle(RNColor.textContentMuted)
            }
        }
    }
}

// MARK: - Comment

struct CommentModel: Identifiable, Hashable {
    let id = UUID()
    let author: String
    let body: String
    let timeAgo: String
    var canDelete: Bool = false
    var replies: [CommentModel] = []
}

struct CommentRow: View {
    let comment: CommentModel
    var onReply: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: RNSpacing.sm) {
            HStack(spacing: RNSpacing.sm) {
                RNAvatar(name: comment.author, size: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.author)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(RNColor.textContent)
                    Label(comment.timeAgo, systemImage: "clock")
                        .font(.system(size: 11))
                        .foregroundStyle(RNColor.textContentMuted)
                }
                Spacer()
                if comment.canDelete {
                    Button { /* delete */ } label: {
                        Label("삭제", systemImage: "trash")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(RNColor.textContentMuted)
                }
            }
            Text(comment.body)
                .font(.system(size: 14))
                .foregroundStyle(RNColor.textContentSecondary)
                .lineSpacing(2)

            HStack {
                Button { onReply?() } label: {
                    Label("답글", systemImage: "bubble.left")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(RNColor.textContentMuted)
            }

            if !comment.replies.isEmpty {
                VStack(alignment: .leading, spacing: RNSpacing.sm) {
                    ForEach(comment.replies) { reply in
                        CommentRow(comment: reply)
                    }
                }
                .padding(.leading, RNSpacing.lg)
            }
        }
        .padding(RNSpacing.md)
        .background(RNColor.bgSurfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: RNRadius.lg, style: .continuous))
    }
}

// MARK: - SummaryPanel — 핵심 요약

struct SummaryPanel: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: RNSpacing.sm) {
            Label("핵심 요약", systemImage: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(RNColor.brandForeground)

            ForEach(Array(items.enumerated()), id: \.offset) { i, s in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(i + 1).")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(RNColor.brandForeground.opacity(0.8))
                    Text(s)
                        .font(.system(size: 14))
                        .foregroundStyle(RNColor.brandForeground)
                        .lineSpacing(3)
                }
            }
        }
        .padding(RNSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            // The single approved gradient in the system: 핵심 요약 panel.
            LinearGradient(colors: [RNColor.brand, RNColor.brandHover],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: RNRadius.lg, style: .continuous))
    }
}

// MARK: - Prose capsule (도입 / 결론)

struct ProseCapsule: View {
    enum Kind { case info, brand }
    let kind: Kind
    let title: String
    let body: String

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(kind == .brand ? RNColor.brand : RNColor.infoText)
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(RNColor.textContent)
                Text(body)
                    .font(.system(size: 14))
                    .foregroundStyle(RNColor.textContentSecondary)
                    .lineSpacing(3)
            }
            .padding(RNSpacing.md)
        }
        .background(RNColor.bgSurfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: RNRadius.md, style: .continuous))
    }
}

// MARK: - Form field (label + content)

struct RNField<Content: View>: View {
    let label: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(RNColor.textContentSecondary)
            content()
        }
    }
}

struct RNTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        Group {
            if isSecure { SecureField(placeholder, text: $text) }
            else        { TextField(placeholder, text: $text) }
        }
        .textFieldStyle(.plain)
        .font(.system(size: 15))
        .foregroundStyle(RNColor.textContent)
        .padding(.horizontal, 12).padding(.vertical, 12)
        .frame(minHeight: 44)
        .background(RNColor.bgSurfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: RNRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RNRadius.md, style: .continuous)
                .strokeBorder(RNColor.borderStrong, lineWidth: 1)
        )
    }
}
