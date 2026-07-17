import SwiftUI

struct FeedComposerView: View {
    @State private var viewModel = FeedComposerViewModel()
    let onSubmitted: () -> Void

    @FocusState private var isContentFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                TextField(
                    "지금 무슨 생각을 하고 있나요?",
                    text: $viewModel.content,
                    axis: .vertical
                )
                .lineLimit(1...8)
                .font(.body)
                .focused($isContentFocused)
                .onChange(of: viewModel.content) { _, newValue in
                    if newValue.count > FeedComposerViewModel.maxCharacters {
                        viewModel.content = String(
                            newValue.prefix(FeedComposerViewModel.maxCharacters))
                    }
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            HStack(spacing: 12) {
                Text("\(viewModel.content.count) / \(FeedComposerViewModel.maxCharacters)")
                    .font(.caption)
                    .foregroundStyle(viewModel.remainingCharacters == 0 ? .red : .secondary)
                    .monospacedDigit()

                Spacer()

                if viewModel.isSubmitting {
                    ProgressView()
                } else {
                    Button("게시") {
                        Task {
                            let wasEmpty = viewModel.content.isEmpty
                            await viewModel.submit()
                            if !wasEmpty && viewModel.content.isEmpty
                                && viewModel.errorMessage == nil {
                                onSubmitted()
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
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemBackground))
    }
}

#Preview {
    FeedComposerView(onSubmitted: {})
}
