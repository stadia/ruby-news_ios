import SafariServices
import SwiftUI

/// `SFSafariViewController`를 SwiftUI 시트로 표시하기 위한 래퍼.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
