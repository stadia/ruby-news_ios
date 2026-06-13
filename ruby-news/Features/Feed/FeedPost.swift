import Foundation

enum FeedPostType: String, Decodable {
    case short
    case blog
    case comment
}

struct FeedResponse: Decodable {
    let posts: [FeedPost]
    let pagination: FeedPagination
}

struct FeedPagination: Decodable, Equatable {
    let nextPage: String?
    let limit: Int

    enum CodingKeys: String, CodingKey {
        case nextPage
        case limit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        limit = try container.decode(Int.self, forKey: .limit)
        // next_page는 서버의 pagy(:countless)에서 정수로 반환되거나 null.
        // iOS에서는 opaque string으로 처리한다.
        if let intValue = try? container.decode(Int.self, forKey: .nextPage) {
            nextPage = String(intValue)
        } else if let stringValue = try? container.decode(String.self, forKey: .nextPage) {
            nextPage = stringValue
        } else {
            nextPage = nil
        }
    }

    init(nextPage: String? = nil, limit: Int) {
        self.nextPage = nextPage
        self.limit = limit
    }
}

struct FeedLink: Equatable {
    let text: String
    let url: URL
}

struct MediaAttachment: Decodable, Equatable, Hashable {
    let url: URL
    let mediaType: String?
    let name: String?
}

/// 배열 디코딩 중 개별 요소 실패를 nil로 흡수해, 잘못된 한 항목이
/// 컬렉션 전체 디코딩을 깨지 않도록 한다.
private struct FailableDecodable<T: Decodable>: Decodable {
    let value: T?
    init(from decoder: Decoder) throws {
        value = try? T(from: decoder)
    }
}

struct FeedPost: Decodable, Identifiable, Equatable, Hashable {
    let id: Int
    let slug: String?
    let body: String
    let postType: FeedPostType
    let status: String?
    let createdAt: Date?
    let updatedAt: Date?
    var likesCount: Int
    var boostsCount: Int
    var liked: Bool
    var boosted: Bool
    let authorName: String?
    let authorHost: String?
    let articleSlug: String?
    let parentSlug: String?
    let boostedBy: String?
    let mediaAttachments: [MediaAttachment]
    let authorAvatarURL: URL?

    var isInteractive: Bool {
        slug?.isEmpty == false
    }

    var imageAttachments: [MediaAttachment] {
        mediaAttachments.filter { $0.mediaType?.hasPrefix("image/") == true }
    }

    /// 서버는 `body`를 `<p>...</p>` 형태의 HTML로 내려준다. SwiftUI `List`(UICollectionView)
    /// 셀 본문에서 `NSAttributedString`의 HTML 파서를 호출하면 중첩 런루프가 컬렉션 뷰의
    /// 셀 dequeue 레이아웃과 충돌해 크래시가 발생한다. 설계 스펙도 "plain post body"를 요구하므로
    /// 런루프를 돌리지 않는 순수 문자열 처리로 태그를 제거한 평문을 제공한다.
    var displayBody: String {
        Self.plainText(fromHTML: body)
    }

    /// 본문 HTML의 `<a href="...">텍스트</a>` 앵커를 문서 순서대로 추출한다.
    /// `text`는 `displayBody`에 나타나는 평문과 동일하게 정리된다.
    var links: [FeedLink] {
        Self.anchorLinks(fromHTML: body)
    }

    static func anchorLinks(fromHTML html: String) -> [FeedLink] {
        guard let regex = Self.anchorRegex else { return [] }
        let ns = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: ns.length))
        return matches.compactMap { match in
            let rawHref = ns.substring(with: match.range(at: 1))
            let rawText = ns.substring(with: match.range(at: 2))
            // href는 HTML 블록이 아니므로 엔티티 디코딩만 한다.
            // (plainText의 블록/트림 파이프라인은 URL에 부적절)
            let href = decodeEntities(rawHref)
            // 앵커 내부 텍스트는 중첩 태그가 있을 수 있으므로 평문화한다.
            let text = plainText(fromHTML: rawText)
            guard !text.isEmpty, let url = URL(string: href) else { return nil }
            return FeedLink(text: text, url: url)
        }
    }

    /// `links`는 셀 렌더마다 호출되므로 정규식을 매번
    /// 재컴파일하지 않도록 한 번만 컴파일한다.
    private static let anchorRegex: NSRegularExpression? = {
        let pattern = "<a\\b[^>]*?href\\s*=\\s*[\"']([^\"']*)[\"'][^>]*>(.*?)</a>"
        return try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )
    }()

    static func plainText(fromHTML html: String) -> String {
        var text = html
        // 블록 경계와 줄바꿈 태그를 개행으로 치환한다.
        for token in ["<br>", "<br/>", "<br />", "</p>", "</div>", "</li>",
                      "</h1>", "</h2>", "</h3>", "</h4>", "</h5>", "</h6>", "</blockquote>"] {
            text = text.replacingOccurrences(
                of: token,
                with: "\n",
                options: [.caseInsensitive]
            )
        }
        // 남은 모든 태그 제거.
        text = text.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: [.regularExpression]
        )
        text = decodeEntities(text)
        // 줄 단위 공백은 트림하되, 작성자가 의도한 문단 사이 빈 줄은 보존한다.
        // 연속된 빈 줄은 최대 한 줄(\n\n)로 합치고 양끝 공백/개행은 제거한다.
        let trimmedLines = text
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\n")
        return trimmedLines
            .replacingOccurrences(of: "\n{3,}", with: "\n\n", options: [.regularExpression])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func decodeEntities(_ value: String) -> String {
        var result = value
        let entities: [(String, String)] = [
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&#39;", "'"),
            ("&#x27;", "'"),
            ("&apos;", "'"),
            ("&nbsp;", "\u{00a0}")
        ]
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        // &amp;는 이중 디코딩을 피하기 위해 마지막에 처리한다.
        return result.replacingOccurrences(of: "&amp;", with: "&")
    }

    enum CodingKeys: String, CodingKey {
        case id
        case slug
        case body
        case postType
        case status
        case createdAt
        case updatedAt
        case likesCount
        case boostsCount
        case liked
        case boosted
        case authorName
        case authorHost
        case articleSlug
        case parentSlug
        case boostedBy
        case mediaAttachments
        case authorAvatarURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        slug = try container.decodeIfPresent(String.self, forKey: .slug)
        body = try container.decode(String.self, forKey: .body)
        postType = try container.decode(FeedPostType.self, forKey: .postType)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        likesCount = try container.decode(Int.self, forKey: .likesCount)
        boostsCount = try container.decode(Int.self, forKey: .boostsCount)
        liked = try container.decode(Bool.self, forKey: .liked)
        boosted = try container.decode(Bool.self, forKey: .boosted)
        authorName = try container.decodeIfPresent(String.self, forKey: .authorName)
        authorHost = try container.decodeIfPresent(String.self, forKey: .authorHost)
        articleSlug = try container.decodeIfPresent(String.self, forKey: .articleSlug)
        parentSlug = try container.decodeIfPresent(String.self, forKey: .parentSlug)
        boostedBy = try container.decodeIfPresent(String.self, forKey: .boostedBy)
        // 잘못된 URL 문자열이 포스트 전체 디코딩을 깨지 않도록 String으로 받아 변환한다.
        if let avatarString = try container.decodeIfPresent(String.self, forKey: .authorAvatarURL) {
            authorAvatarURL = URL(string: avatarString)
        } else {
            authorAvatarURL = nil
        }
        let rawAttachments = try container.decodeIfPresent(
            [FailableDecodable<MediaAttachment>].self,
            forKey: .mediaAttachments
        ) ?? []
        mediaAttachments = rawAttachments.compactMap(\.value)

        let createdAtValue = try container.decode(String.self, forKey: .createdAt)
        let updatedAtValue = try container.decode(String.self, forKey: .updatedAt)
        createdAt = Self.parseDate(createdAtValue)
        updatedAt = Self.parseDate(updatedAtValue)
    }

    private static func parseDate(_ value: String) -> Date? {
        fractionalDateFormatter.date(from: value)
            ?? dateFormatter.date(from: value)
            ?? rubyDateFormatter.date(from: value)
    }

    private static let fractionalDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let dateFormatter = ISO8601DateFormatter()

    /// 서버의 Alba/Oj serialization이 반환하는 Ruby Time 형식용 포매터. (예: "2026-03-21 16:40:35 +0900")
    private static let rubyDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return formatter
    }()
}
