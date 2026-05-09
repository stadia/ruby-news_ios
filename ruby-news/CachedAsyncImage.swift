//
//  CachedAsyncImage.swift
//  ruby-news
//

import SwiftUI

/// AsyncImage와 동일한 API로, ImageCache를 통해 메모리/디스크 캐시를 사용한다.
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var uiImage: UIImage?

    var body: some View {
        Group {
            if let uiImage {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            guard let url else { return }
            uiImage = await ImageCache.shared.image(for: url)
        }
    }
}
