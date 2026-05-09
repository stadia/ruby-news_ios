// ArticleDetailView.swift — 기사 상세 + 핵심 요약 + 댓글 스레드.
// Mirrors the web detail page: header → 핵심 요약 panel → prose capsules → comments.

import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @State private var draftComment: String = ""
    @State private var bodyFontSize: Double = 15.0     // exposed via Tweaks-equivalent

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RNSpacing.lg) {
                header
                SummaryPanel(items: article.summaryKey)
                proseBody
                commentsSection
            }
            .padding(RNSpacing.md)
            .padding(.bottom, RNSpacing.xl)
        }
        .background(RNColor.bgApp.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("폰트 작게")  { bodyFontSize = max(13, bodyFontSize - 1) }
                    Button("폰트 기본")  { bodyFontSize = 15 }
                    Button("폰트 크게")  { bodyFontSize = min(22, bodyFontSize + 1) }
                    Divider()
                    Button("원문 열기", systemImage: "arrow.up.right.square") { /* open url */ }
                    ShareLink(item: article.url) { Label("공유", systemImage: "square.and.arrow.up") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    // —— sections ————————————————————————————————————————————————————————

    private var header: some View {
        VStack(alignment: .leading, spacing: RNSpacing.sm) {
            Text(article.titleKo)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(RNColor.textContent)
                .lineSpacing(4)
            if let en = article.titleEn, en != article.titleKo {
                Text(en)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(RNColor.textContentSecondary)
            }
            HStack(spacing: RNSpacing.md) {
                HStack(spacing: 8) {
                    RNAvatar(name: article.author, size: 32)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("작성자").font(.system(size: 11)).foregroundStyle(RNColor.textContentMuted)
                        Text(article.author).font(.system(size: 13, weight: .medium)).foregroundStyle(RNColor.textContent)
                    }
                }
                Spacer()
                Label("\(article.likes)", systemImage: "heart")
                    .foregroundStyle(RNColor.dangerText)
                    .font(.system(size: 13))
            }
            // Source URL strip
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.right.square.fill")
                    .foregroundStyle(RNColor.brandForeground)
                    .padding(8).background(RNColor.infoSolid).clipShape(RoundedRectangle(cornerRadius: 8))
                Text(article.url)
                    .font(.system(size: 12))
                    .foregroundStyle(RNColor.infoText)
                    .lineLimit(1).truncationMode(.middle)
            }
            .padding(RNSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RNColor.bgSurfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: RNRadius.md, style: .continuous))
        }
    }

    private var proseBody: some View {
        VStack(alignment: .leading, spacing: RNSpacing.md) {
            ProseCapsule(
                kind: .info,
                title: "도입",
                body: "Hotwire Native는 기존의 Hotwire 스택(Turbo + Stimulus)을 모바일 환경에 자연스럽게 확장합니다. 웹뷰를 단순한 백업 수단으로 보지 않고, 네이티브 셸과의 협업 파트너로 끌어올린 점이 핵심입니다."
            )

            Text("경로 구성으로 화면 전환을 표현하기")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(RNColor.textContent)

            Text("iOS와 Android 모두 path configuration JSON을 통해 어떤 URL이 모달로 열릴지, 어떤 URL이 풀스크린으로 푸시될지 선언합니다. Rails 앱은 자신이 모바일 셸 안에서 동작한다는 사실을 거의 인지할 필요가 없습니다.")
                .font(.system(size: bodyFontSize))
                .lineSpacing(4)
                .foregroundStyle(RNColor.textContentSecondary)

            Text("Stimulus 컨트롤러는 그대로 동작하고, Turbo Streams와 Frames도 그대로 흐릅니다. 즉, 단일 코드베이스에서 웹과 모바일의 인터랙션 패턴을 모두 표현할 수 있다는 의미입니다.")
                .font(.system(size: bodyFontSize))
                .lineSpacing(4)
                .foregroundStyle(RNColor.textContentSecondary)

            ProseCapsule(
                kind: .brand,
                title: "결론",
                body: "Hotwire Native는 모바일 앱은 따로 설계해야 한다는 가정을 흔드는 도구입니다. Rails 8과의 결합 속에서, 작은 팀일수록 Hotwire Native의 가치는 빠르게 커집니다."
            )
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: RNSpacing.md) {
            Label("댓글 (\(MockComments.thread.count))", systemImage: "bubble.left.and.bubble.right")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(RNColor.textContent)

            CommentComposer(text: $draftComment)

            ForEach(MockComments.thread) { c in
                CommentRow(comment: c)
            }
        }
    }
}

// MARK: - Composer

struct CommentComposer: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: RNSpacing.sm) {
            Label("댓글 작성", systemImage: "square.and.pencil")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(RNColor.textContent)
            TextEditor(text: $text)
                .frame(minHeight: 100)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(RNColor.bgApp)
                .clipShape(RoundedRectangle(cornerRadius: RNRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: RNRadius.md, style: .continuous)
                        .strokeBorder(RNColor.borderStrong, lineWidth: 1)
                )
            HStack {
                Label("정중하고 건설적인 댓글을 작성해 주세요.", systemImage: "info.circle")
                    .font(.system(size: 11))
                    .foregroundStyle(RNColor.textContentMuted)
                Spacer()
                RNButton(title: "댓글 작성", variant: .info, size: .sm) { /* submit */ }
                    .fixedSize()
            }
        }
        .padding(RNSpacing.md)
        .background(RNColor.bgSurfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: RNRadius.lg, style: .continuous))
    }
}
