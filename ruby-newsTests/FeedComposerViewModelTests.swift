import Foundation
import Testing

@testable import ruby_news

@MainActor
@Suite(.serialized)
struct FeedComposerViewModelTests {
    @Test
    func initialStateIsEmptyAndDisabled() {
        let viewModel = FeedComposerViewModel(submit: { _ in Self.makeDraft() })

        #expect(viewModel.content.isEmpty)
        #expect(viewModel.isSubmitting == false)
        #expect(viewModel.canSubmit == false)
        #expect(viewModel.remainingCharacters == FeedComposerViewModel.maxCharacters)
    }

    @Test
    func canSubmitBecomesTrueWhenContentWithinLimit() {
        let viewModel = FeedComposerViewModel(submit: { _ in Self.makeDraft() })

        viewModel.content = "안녕하세요"

        #expect(viewModel.canSubmit)
        #expect(viewModel.remainingCharacters == FeedComposerViewModel.maxCharacters - 5)
    }

    @Test
    func whitespaceOnlyContentIsNotSubmittable() {
        let viewModel = FeedComposerViewModel(submit: { _ in Self.makeDraft() })

        viewModel.content = "   \n  "

        #expect(viewModel.canSubmit == false)
    }

    @Test
    func contentAtLimitDisablesSubmit() {
        let viewModel = FeedComposerViewModel(submit: { _ in Self.makeDraft() })
        let text = String(repeating: "가", count: FeedComposerViewModel.maxCharacters)

        viewModel.content = text

        #expect(viewModel.content.count == FeedComposerViewModel.maxCharacters)
        #expect(viewModel.canSubmit == false)
        #expect(viewModel.remainingCharacters == 0)
    }

    @Test
    func submitPassesContentToHandlerAndResetsOnSuccess() async throws {
        var received: [String] = []
        let viewModel = FeedComposerViewModel(submit: { content in
            received.append(content)
            return Self.makeDraft()
        })

        viewModel.content = "첫 포스트"
        await viewModel.submit()

        #expect(received == ["첫 포스트"])
        #expect(viewModel.content.isEmpty)
        #expect(viewModel.isSubmitting == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func submitIgnoresEmptyContent() async {
        var callCount = 0
        let viewModel = FeedComposerViewModel(submit: { _ in
            callCount += 1
            return Self.makeDraft()
        })

        await viewModel.submit()

        #expect(callCount == 0)
    }

    @Test
    func submitExposesLastSubmittedPostOnSuccess() async throws {
        let draft = Self.makeDraft()
        let viewModel = FeedComposerViewModel(submit: { _ in draft })

        viewModel.content = "안녕"
        await viewModel.submit()

        #expect(viewModel.lastSubmittedPost?.body == "post-1")
    }

    private static func makeDraft() -> FeedPost {
        let json = """
            {
              "id": 1,
              "slug": "post-1",
              "body": "post-1",
              "post_type": "short",
              "status": "published",
              "created_at": "2026-06-13 00:30:00 +0900",
              "updated_at": "2026-06-13 00:31:00 +0900",
              "likes_count": 0,
              "boosts_count": 0,
              "liked": false,
              "boosted": false,
              "author_name": "Author 1",
              "author_host": null,
              "article_slug": null,
              "parent_slug": null,
              "boosted_by": null
            }
            """
        return try! APIClient.decoder.decode(FeedPost.self, from: Data(json.utf8))
    }
}
