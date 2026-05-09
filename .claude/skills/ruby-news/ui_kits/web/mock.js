// Mock data shared across UI kit demo pages.
const MOCK_ARTICLES = [
    {
        id: 1,
        titleKo: "Hotwire Native가 모바일 앱 개발을 어떻게 단순화하는가",
        title: "How Hotwire Native Simplifies Mobile App Development",
        host: "github.com",
        author: "news_kr",
        publishedAt: "2026-05-06",
        likes: 24, comments: 4,
        summaryKey: [
            "Hotwire Native는 Turbo와 Stimulus를 iOS와 Android에 그대로 가져옵니다.",
            "웹뷰 한 번에 네이티브 셸을 얹는 구조로 코드 공유율이 높습니다.",
            "Rails 8과의 통합 사례 및 마이그레이션 패턴을 살펴봅니다.",
        ],
        url: "https://github.com/hotwired/hotwire-native-ios",
    },
    {
        id: 2,
        titleKo: "Rails 8: Solid Queue, Solid Cache, Solid Cable 완전 정리",
        title: "Rails 8: Bundling Solid Queue, Cache, and Cable",
        host: "rubyweekly.com",
        author: "news_kr",
        publishedAt: "2026-05-05",
        likes: 38, comments: 9,
        summaryKey: [
            "Solid 스택은 Redis 없이 Postgres만으로 백엔드를 구성합니다.",
            "Solid Queue가 Sidekiq을 대체할 수 있는 케이스를 정리합니다.",
            "운영 환경에서 마주칠 수 있는 함정과 튜닝 포인트를 다룹니다.",
        ],
        url: "https://rubyweekly.com/issues/722",
    },
    {
        id: 3,
        titleKo: "pgvector + Rails로 1주만에 추천 기능 만들기",
        title: "Building Article Recommendations in 1 Week with pgvector + Rails",
        host: "shopify.engineering",
        author: "mkim",
        publishedAt: "2026-05-04",
        likes: 51, comments: 12,
        summaryKey: [
            "OpenAI text-embedding-3-small으로 글 본문을 벡터화합니다.",
            "pgvector의 HNSW 인덱스로 코사인 유사도를 빠르게 조회합니다.",
            "Rails Active Record와 매끄럽게 통합되는 ActiveSupport 패턴을 소개합니다.",
        ],
        url: "https://shopify.engineering/recommendations-pgvector",
    },
    {
        id: 4,
        titleKo: "Phlex 2.0: Ruby 컴포넌트로 뷰 작성하기",
        title: "Phlex 2.0: Writing Views as Plain Ruby Components",
        host: "phlex.fun",
        author: "news_kr",
        publishedAt: "2026-05-03",
        likes: 17, comments: 6,
        summaryKey: [
            "Phlex 2.0은 ERB의 대안으로 정밀한 컴파일 시간 검증을 제공합니다.",
            "RubyUI / phlex_icons과의 결합으로 디자인 시스템을 코드로 표현합니다.",
            "기존 ERB 뷰를 점진적으로 마이그레이션하는 전략을 소개합니다.",
        ],
        url: "https://phlex.fun/2.0",
    },
    {
        id: 5,
        titleKo: "Kamal 2: 멀티 호스트 배포가 더 쉬워졌다",
        title: "Kamal 2: Multi-host Deploys Get Easier",
        host: "kamal-deploy.org",
        author: "jeffdean",
        publishedAt: "2026-05-02",
        likes: 22, comments: 3,
        summaryKey: [
            "Kamal 2는 컨테이너 기반 배포의 대시보드 UX를 새로 다듬었습니다.",
            "여러 호스트에 동시에 배포하면서도 롤백을 안전하게 관리합니다.",
            "Rails 8 기본 템플릿에 Kamal이 포함된 의미를 짚어봅니다.",
        ],
        url: "https://kamal-deploy.org/blog/kamal-2",
    },
    {
        id: 6,
        titleKo: "Active Record 8의 비동기 쿼리, 실전 가이드",
        title: "Async Queries in Active Record 8: A Practical Guide",
        host: "evilmartians.com",
        author: "skim",
        publishedAt: "2026-05-01",
        likes: 14, comments: 2,
        summaryKey: [
            "load_async와 promise 기반 매처를 사용해 N+1을 줄입니다.",
            "동시 실행이 도움이 되는 케이스와 그렇지 않은 케이스를 구분합니다.",
            "Datadog APM 그래프로 본 개선 효과를 공유합니다.",
        ],
        url: "https://evilmartians.com/active-record-8-async",
    },
];

const MOCK_COMMENTS = [
    {
        author: "jeffdean", tone: "brand", timeAgo: "9분 전",
        canDelete: true,
        body: "Hotwire Native 정말 잘 정리된 글이네요. iOS에서 path configuration 다루는 부분이 특히 좋았습니다.",
    },
    {
        author: "mkim", tone: "info", timeAgo: "27분 전",
        body: "동감입니다. Stimulus 컨트롤러 공유 패턴이 인상적이었어요.",
    },
    {
        author: "skim", tone: "neutral", timeAgo: "1시간 전",
        body: "Android에서 path 매처가 의외로 까다로웠던 기억이 나네요. 다음 글에서 더 깊게 다뤄주시면 좋겠습니다.",
    },
];

const MOCK_RECENT_COMMENTS = [
    { author: "jeffdean", body: "Hotwire Native 정말 잘 정리된 글이네요. iOS에서 path configuration 다루는 부분이 특히 좋았습니다.", timeAgo: "9분 전" },
    { author: "mkim", body: "Solid Queue로 옮긴 후 운영 비용이 절반 이하로 떨어졌습니다.", timeAgo: "1시간 전" },
    { author: "skim", body: "pgvector HNSW 인덱스의 m, ef_construction 튜닝이 핵심이에요.", timeAgo: "3시간 전" },
];

Object.assign(window, { MOCK_ARTICLES, MOCK_COMMENTS, MOCK_RECENT_COMMENTS });
