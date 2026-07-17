import SwiftUI

struct FeedComposerView: View {
    @State private var viewModel = FeedComposerViewModel()
    let onSubmitted: () -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isContentFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                TextField(
                    "지금 무슨 생각을 하고 있나요?",
                    text: $viewModel.content,
                    axis: .vertical
                )
                .font(.body)
                .focused($isContentFocused)
                .padding(.horizontal)
                .padding(.top, 12)
                .onChange(of: viewModel.content) { _, newValue in
                    if newValue.count > FeedComposerViewModel.maxCharacters {
                        viewModel.content = String(
                            newValue.prefix(FeedComposerViewModel.maxCharacters))
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                Spacer()
            }
            .navigationTitle("새 글")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSubmitting {
                        ProgressView()
                    } else {
                        HStack(spacing: 10) {
                            CharacterCountRing(
                                count: viewModel.content.count,
                                limit: FeedComposerViewModel.maxCharacters
                            )

                            Button("게시") {
                                Task {
                                    await viewModel.submit()
                                    if viewModel.content.isEmpty && viewModel.errorMessage == nil {
                                        onSubmitted()
                                        dismiss()
                                    }
                                }
                            }
                            .font(.subheadline.weight(.semibold))
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(!viewModel.canSubmit)
                        }
                    }
                }
            }
            .onAppear { isContentFocused = true }
        }
    }
}

/// 마스토돈/트위터 스타일의 원형 글자 수 인디케이터.
/// 한계에 가까워지면 색이 바뀌고, 20자 이하 남으면 남은 글자 수를 표시한다.
private struct CharacterCountRing: View {
    let count: Int
    let limit: Int

    private var progress: Double {
        guard limit > 0 else { return 0 }
        return min(1, Double(count) / Double(limit))
    }

    private var remaining: Int { limit - count }

    private var color: Color {
        switch remaining {
        case ..<0: .red
        case 0...20: .orange
        default: .accentColor
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(.red)
                .padding(3)
            Circle()
                .stroke(Color(uiColor: .systemGray5), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))

            if remaining <= 20 {
                Text("\(remaining)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
        }
        .frame(width: 24, height: 24)
        .animation(.easeOut(duration: 0.15), value: progress)
        .accessibilityLabel("남은 글자 수 \(remaining)")
    }
}

#Preview {
    FeedComposerView(onSubmitted: {})
}
