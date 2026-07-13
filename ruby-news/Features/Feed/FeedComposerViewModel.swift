import Foundation
import Observation

@MainActor
@Observable
final class FeedComposerViewModel {
    typealias Submit = (String) async throws -> FeedPost

    static let maxCharacters = 500

    private let submitAction: Submit
    private var latestSubmitRequestID: UUID?

    var content: String = ""
    var isSubmitting: Bool = false
    var errorMessage: String?
    var lastSubmittedPost: FeedPost?

    init(submit: @escaping Submit) {
        submitAction = submit
    }

    init(apiClient: APIClient? = nil, tokenStore: TokenStore? = nil) {
        let tokenStore = tokenStore ?? KeychainTokenStore()
        let client = apiClient ?? APIClient.authenticated(tokenStore: tokenStore)
        submitAction = { content in
            try await client.createPost(content: content)
        }
    }

    var trimmedContent: String {
        content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSubmit: Bool {
        !trimmedContent.isEmpty && content.count < Self.maxCharacters && !isSubmitting
    }

    var remainingCharacters: Int {
        max(0, Self.maxCharacters - content.count)
    }

    func submit() async {
        guard canSubmit else { return }
        let payload = trimmedContent

        let requestID = UUID()
        latestSubmitRequestID = requestID
        isSubmitting = true
        errorMessage = nil

        do {
            let post = try await submitAction(payload)
            guard latestSubmitRequestID == requestID else { return }
            content = ""
            lastSubmittedPost = post
        } catch APIError.unauthorized {
            guard latestSubmitRequestID == requestID else { return }
            errorMessage = "로그인이 필요합니다."
        } catch APIError.unacceptableStatusCode(401) {
            guard latestSubmitRequestID == requestID else { return }
            errorMessage = "로그인이 필요합니다."
        } catch {
            guard latestSubmitRequestID == requestID else { return }
            errorMessage = "게시하지 못했습니다."
        }

        if latestSubmitRequestID == requestID {
            isSubmitting = false
        }
    }
}
