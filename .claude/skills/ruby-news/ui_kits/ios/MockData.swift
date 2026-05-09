// MockData.swift — Korean prototype copy shared across screens.
// Mirrors `ui_kits/web/mock.js` so designers comparing surfaces see identical content.

import Foundation

enum MockArticles {
    static let all: [Article] = [
        .init(
            id: 1,
            titleKo: "Hotwire Native가 모바일 앱 개발을 어떻게 단순화하는가",
            titleEn: "How Hotwire Native Simplifies Mobile App Development",
            host: "github.com",
            author: "news_kr",
            publishedAt: "2026-05-06",
            likes: 24, comments: 4,
            summaryKey: [
                "Hotwire Native는 Turbo와 Stimulus를 iOS와 Android에 그대로 가져옵니다.",
                "웹뷰 한 번에 네이티브 셸을 얹는 구조로 코드 공유율이 높습니다.",
                "Rails 8과의 통합 사례 및 마이그레이션 패턴을 살펴봅니다.",
            ],
            url: "https://github.com/hotwired/hotwire-native-ios"
        ),
        .init(
            id: 2,
            titleKo: "Rails 8: Solid Queue, Solid Cache, Solid Cable 완전 정리",
            titleEn: "Rails 8: Bundling Solid Queue, Cache, and Cable",
            host: "rubyweekly.com",
            author: "news_kr",
            publishedAt: "2026-05-05",
            likes: 38, comments: 9,
            summaryKey: [
                "Solid 스택은 Redis 없이 Postgres만으로 백엔드를 구성합니다.",
                "Solid Queue가 Sidekiq을 대체할 수 있는 케이스를 정리합니다.",
                "운영 환경에서 마주칠 수 있는 함정과 튜닝 포인트를 다룹니다.",
            ],
            url: "https://rubyweekly.com/issues/722"
        ),
        .init(
            id: 3,
            titleKo: "pgvector + Rails로 1주만에 추천 기능 만들기",
            titleEn: "Building Article Recommendations in 1 Week with pgvector + Rails",
            host: "shopify.engineering",
            author: "mkim",
            publishedAt: "2026-05-04",
            likes: 51, comments: 12,
            summaryKey: [
                "OpenAI text-embedding-3-small으로 글 본문을 벡터화합니다.",
                "pgvector의 HNSW 인덱스로 코사인 유사도를 빠르게 조회합니다.",
                "Rails Active Record와 매끄럽게 통합되는 ActiveSupport 패턴을 소개합니다.",
            ],
            url: "https://shopify.engineering/recommendations-pgvector"
        ),
        .init(
            id: 4,
            titleKo: "Phlex 2.0: Ruby 컴포넌트로 뷰 작성하기",
            titleEn: "Phlex 2.0: Writing Views as Plain Ruby Components",
            host: "phlex.fun",
            author: "news_kr",
            publishedAt: "2026-05-03",
            likes: 17, comments: 6,
            summaryKey: [
                "Phlex 2.0은 ERB의 대안으로 정밀한 컴파일 시간 검증을 제공합니다.",
                "RubyUI / phlex_icons과의 결합으로 디자인 시스템을 코드로 표현합니다.",
                "기존 ERB 뷰를 점진적으로 마이그레이션하는 전략을 소개합니다.",
            ],
            url: "https://phlex.fun/2.0"
        ),
    ]
}

enum MockComments {
    static let thread: [CommentModel] = [
        .init(
            author: "jeffdean",
            body: "Hotwire Native 정말 잘 정리된 글이네요. iOS에서 path configuration 다루는 부분이 특히 좋았습니다.",
            timeAgo: "9분 전",
            canDelete: true,
            replies: [
                .init(author: "mkim",
                      body: "동감입니다. Stimulus 컨트롤러 공유 패턴이 인상적이었어요.",
                      timeAgo: "5분 전")
            ]
        ),
        .init(author: "skim",
              body: "Android에서 path 매처가 의외로 까다로웠던 기억이 나네요. 다음 글에서 더 깊게 다뤄주시면 좋겠습니다.",
              timeAgo: "1시간 전")
    ]
}
