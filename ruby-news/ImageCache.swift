//
//  ImageCache.swift
//  ruby-news
//

import UIKit
import CryptoKit

/// 메모리 + 디스크 이중 캐시.
/// 같은 URL은 앱 재실행 후에도 디스크에서 즉시 로드한다.
actor ImageCache {
    static let shared = ImageCache()

    private let memoryCache = NSCache<NSURL, UIImage>()
    private let cacheDirectory: URL
    let fetch: (URL) async throws -> Data

    init(
        cacheDirectory: URL? = nil,
        fetch: @escaping (URL) async throws -> Data = { url in
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        }
    ) {
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = cacheDirectory ?? cachesDir.appendingPathComponent("AvatarImages")
        self.fetch = fetch
        try? FileManager.default.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)
    }

    /// URL에 해당하는 이미지를 반환한다. 메모리 → 디스크 → 네트워크 순으로 조회한다.
    func image(for url: URL) async -> UIImage? {
        // 1. 메모리 캐시
        if let cached = memoryCache.object(forKey: url as NSURL) {
            return cached
        }

        // 2. 디스크 캐시
        let diskURL = cacheFileURL(for: url)
        if let data = try? Data(contentsOf: diskURL), let image = UIImage(data: data) {
            memoryCache.setObject(image, forKey: url as NSURL)
            return image
        }

        // 3. 네트워크
        guard let data = try? await fetch(url), let image = UIImage(data: data) else {
            return nil
        }

        memoryCache.setObject(image, forKey: url as NSURL)
        try? data.write(to: diskURL, options: .atomic)
        return image
    }

    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    private func cacheFileURL(for url: URL) -> URL {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
        let filename = hash.compactMap { String(format: "%02x", $0) }.joined()
        return cacheDirectory.appendingPathComponent(filename)
    }
}
