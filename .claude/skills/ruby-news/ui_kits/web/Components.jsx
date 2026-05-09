// Ruby News web UI kit — composed components.
// Builds on Icon.jsx + Primitives.jsx.

// ─── Nav ───────────────────────────────────────────────────────────────────
function Nav({ active = "home", signedIn = false, theme = "dark", onTheme }) {
    const item = (key, label, href = "#") => (
        <li>
            <a href={href} className={cn("rn-nav__link", active === key && "rn-nav__link--active")}>
                {label}
            </a>
        </li>
    );
    return (
        <nav className="rn-nav" aria-label="주 네비게이션">
            <div className="rn-nav__inner">
                <a className="rn-brand" href="#">
                    Ruby-News || <span className="rn-brand__accent">루비 AI 뉴스</span>
                </a>
                <ul className="rn-nav__menu">
                    {item("home", "홈")}
                    {item("articles", "지난 글")}
                    {item("others", "그 밖의 뉴스")}
                    <li>
                        <form className="rn-nav__search" role="search" aria-label="기사 검색"
                              onSubmit={(e) => e.preventDefault()}>
                            <input type="search" placeholder="검색..." />
                            <Button type="submit" variant="primary" size="md">검색</Button>
                        </form>
                    </li>
                    {signedIn
                        ? item("profile", "글 등록", "#")
                        : item("login", "로그인", "#")}
                    <li>
                        <Button variant="ghost" size="md" icon onClick={() => onTheme?.()}>
                            {theme === "dark" ? <IconMoon size={18}/> : <IconSun size={18}/>}
                        </Button>
                    </li>
                </ul>
            </div>
        </nav>
    );
}

// ─── Footer ────────────────────────────────────────────────────────────────
function Footer() {
    return (
        <footer className="rn-footer">
            <div className="rn-footer__inner">
                <span>© 2025 <a href="https://ruby-news.kr/">Ruby-News || 루비 AI 뉴스</a>. All Rights Reserved.</span>
                <ul className="rn-footer__links">
                    <li><a href="#"><IconMastodon size={18}/> Mastodon</a></li>
                    <li><a href="#"><IconX size={18}/> Twitter/X</a></li>
                    <li><a href="#"><IconSlack size={18}/> Slack 추가</a></li>
                    <li><a href="#"><IconRss size={18}/> RSS 피드</a></li>
                </ul>
            </div>
        </footer>
    );
}

// ─── Layout shell ──────────────────────────────────────────────────────────
function Layout({ active = "home", signedIn = false, children }) {
    return (
        <div className="rn-shell">
            <a className="rn-skip" href="#main">본문으로 건너뛰기</a>
            <Nav active={active} signedIn={signedIn}/>
            <main id="main" className="rn-main">{children}</main>
            <Footer/>
        </div>
    );
}

// ─── ArticleCard ───────────────────────────────────────────────────────────
function ArticleCard({ article, liked = false }) {
    return (
        <Card className="rn-card--hoverable rn-article-card">
            <Heading level={2} className="rn-article-card__title" style={{ fontSize: "var(--text-lg)" }}>
                <a href="#" style={{ color: "inherit" }}>{article.titleKo}</a>
            </Heading>
            {article.title && article.title !== article.titleKo && (
                <Heading level={3} className="rn-article-card__title-en" style={{ fontSize: "var(--text-base)", fontWeight: "var(--font-medium)" }}>
                    {article.title}
                </Heading>
            )}
            <Badge variant="blue" size="sm" className="rn-text-secondary" >
                {article.host}
            </Badge>
            <ul className="rn-article-card__summary" style={{ marginTop: "var(--space-md)" }}>
                {article.summaryKey.map((s, i) => <li key={i}>{s}</li>)}
            </ul>
            <div className="rn-article-card__meta" style={{ marginTop: "auto" }}>
                <span><IconUser size={14}/> {article.author}</span>
                <span style={{ color: liked ? "var(--danger-text)" : "inherit" }}>
                    {liked ? <IconHeartSolid size={14}/> : <IconHeart size={14}/>} {article.likes}
                </span>
                <span><IconChatBubbleLeftEllipsis size={14}/> {article.comments}</span>
                <span><IconCalendarDays size={14}/> {article.publishedAt}</span>
            </div>
        </Card>
    );
}

// ─── Comment ───────────────────────────────────────────────────────────────
function Comment({ comment, canReply = true, onReply, replies = [] }) {
    return (
        <div className="rn-comment-wrapper">
            <Card className="rn-card--surface-muted">
                <CardContent>
                    <div className="rn-comment__header">
                        <div className="rn-comment__author">
                            <Avatar name={comment.author} tone={comment.tone || "brand"} size="md"/>
                            <div>
                                <div className="rn-comment__name">{comment.author}</div>
                                <div className="rn-comment__time"><IconClock size={12}/> {comment.timeAgo}</div>
                            </div>
                        </div>
                        {comment.canDelete && (
                            <Button variant="ghost" size="sm">
                                <IconTrash size={14}/> 삭제
                            </Button>
                        )}
                    </div>
                    <div className="rn-comment__body">{comment.body}</div>
                    {canReply && (
                        <div className="rn-comment__actions">
                            <Button variant="ghost" size="sm" onClick={onReply}>
                                <IconChatBubbleLeft size={14}/> 답글
                            </Button>
                        </div>
                    )}
                    {replies.length > 0 && (
                        <div className="rn-comment__nested">
                            {replies.map((r, i) => (
                                <div key={i} style={{ marginBottom: "var(--space-sm)" }}>
                                    <Comment comment={r} canReply={false}/>
                                </div>
                            ))}
                        </div>
                    )}
                </CardContent>
            </Card>
        </div>
    );
}

// ─── CommentForm ───────────────────────────────────────────────────────────
function CommentForm({ signedIn = true }) {
    const [value, setValue] = React.useState("");
    if (!signedIn) {
        return (
            <Card className="rn-card--surface-muted">
                <CardContent>
                    <div style={{ fontSize: "var(--text-sm)", color: "var(--text-content-secondary)" }}>
                        <IconInformationCircle size={14}/>{" "}
                        댓글을 작성하려면 <a href="#">로그인</a>이 필요합니다.
                    </div>
                </CardContent>
            </Card>
        );
    }
    return (
        <Card className="rn-card--surface-muted">
            <CardContent>
                <Heading level={4} className="rn-h4" style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: "var(--space-md)" }}>
                    <IconPencilSquare size={18} className="rn-text-info"/> 댓글 작성
                </Heading>
                <FormField label="댓글 내용" htmlFor="comment-body">
                    <TextArea
                        id="comment-body" rows={4}
                        placeholder="댓글을 입력하세요..."
                        maxLength={2000}
                        value={value}
                        onChange={(e) => setValue(e.target.value)}
                    />
                    <div style={{ fontSize: "var(--text-xs)", color: "var(--text-content-muted)", textAlign: "right" }}>
                        {value.length}/2000
                    </div>
                </FormField>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: "var(--space-md)", flexWrap: "wrap" }}>
                    <span style={{ fontSize: "var(--text-xs)", color: "var(--text-content-muted)", display: "inline-flex", alignItems: "center", gap: 4 }}>
                        <IconInformationCircle size={14}/> 정중하고 건설적인 댓글을 작성해 주세요.
                    </span>
                    <Button variant="info" size="lg">댓글 작성</Button>
                </div>
            </CardContent>
        </Card>
    );
}

// ─── ArticleSummaryPanel ───────────────────────────────────────────────────
function SummaryPanel({ items }) {
    return (
        <div className="rn-summary-panel">
            <h2><IconCheckCircle size={20}/> 핵심 요약</h2>
            <ol>
                {items.map((it, i) => (
                    <li key={i}>
                        <span className="rn-summary-panel__num">{i + 1}.</span>
                        <span>{it}</span>
                    </li>
                ))}
            </ol>
        </div>
    );
}

// ─── ProseCapsule ──────────────────────────────────────────────────────────
function ProseCapsule({ kind = "info", title, children }) {
    return (
        <div className={cn("rn-prose-capsule", kind === "brand" && "rn-prose-capsule--brand")}>
            <h3>{title}</h3>
            <p>{children}</p>
        </div>
    );
}

// ─── ArticleHeader (article detail) ────────────────────────────────────────
function ArticleHeader({ article }) {
    return (
        <header style={{ padding: "var(--space-lg)" }}>
            <Heading level={1} className="rn-h1" style={{ marginBottom: "var(--space-md)" }}>
                {article.titleKo}
            </Heading>
            {article.title && article.title !== article.titleKo && (
                <Heading level={2} className="rn-h2" style={{ fontSize: "var(--text-xl)", fontWeight: "var(--font-medium)", color: "var(--text-content-secondary)", marginBottom: "var(--space-md)", wordBreak: "break-word" }}>
                    {article.title}
                </Heading>
            )}
            <div style={{ display: "flex", flexWrap: "wrap", gap: "var(--space-lg)", color: "var(--text-content-secondary)", fontSize: "var(--text-sm)" }}>
                <div style={{ display: "flex", alignItems: "center", gap: "var(--space-sm)" }}>
                    <Avatar name={article.author} tone="brand" size="md"/>
                    <div>
                        <div style={{ fontSize: "var(--text-xs)", color: "var(--text-content-muted)" }}>작성자</div>
                        <div style={{ color: "var(--text-content)", fontWeight: "var(--font-medium)" }}>{article.author}</div>
                    </div>
                </div>
                <div style={{ display: "flex", alignItems: "center", gap: "var(--space-sm)" }}>
                    <IconCalendar size={20} className="rn-text-muted"/>
                    <div>
                        <div style={{ fontSize: "var(--text-xs)", color: "var(--text-content-muted)" }}>발행일</div>
                        <div style={{ color: "var(--text-content)", fontWeight: "var(--font-medium)" }}>{article.publishedAt}</div>
                    </div>
                </div>
                <div style={{ display: "inline-flex", alignItems: "center", gap: 4, color: "var(--danger-text)" }}>
                    <IconHeart size={18}/> {article.likes}
                </div>
            </div>
            <div style={{ marginTop: "var(--space-md)", padding: "var(--space-md)", background: "var(--bg-surface-muted)", borderRadius: "var(--radius-md)", display: "flex", alignItems: "center", gap: "var(--space-sm)" }}>
                <span style={{ width: 36, height: 36, background: "var(--info-solid)", borderRadius: "var(--radius-md)", display: "inline-flex", alignItems: "center", justifyContent: "center", color: "var(--brand-foreground)", flexShrink: 0 }}>
                    <IconArrowTopRightOnSquare size={18}/>
                </span>
                <a href={article.url} style={{ color: "var(--info-text)", fontSize: "var(--text-sm)", fontWeight: "var(--font-medium)", wordBreak: "break-word" }}>
                    {article.url}
                </a>
            </div>
        </header>
    );
}

// ─── RecentCommentsSidebar ─────────────────────────────────────────────────
function RecentCommentsSidebar({ comments }) {
    return (
        <aside className="rn-sidebar">
            <div>
                <h3><IconChatBubbleLeftRight size={18} className="rn-text-info"/> 최근 댓글</h3>
                <div style={{ display: "flex", flexDirection: "column", gap: "var(--space-sm)" }}>
                    {comments.map((c, i) => (
                        <Card key={i} className="rn-card--hoverable" style={{ padding: "var(--space-sm)" }}>
                            <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 6 }}>
                                <Avatar name={c.author} tone="neutral" size="sm"/>
                                <span style={{ fontSize: "var(--text-sm)", fontWeight: "var(--font-medium)", color: "var(--text-content-secondary)" }}>{c.author}</span>
                            </div>
                            <p style={{ fontSize: "var(--text-sm)", color: "var(--text-content-muted)", margin: "0 0 6px", lineHeight: "var(--leading-normal)", display: "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical", overflow: "hidden" }}>
                                {c.body}
                            </p>
                            <div style={{ display: "flex", justifyContent: "space-between", fontSize: "var(--text-xs)", color: "var(--text-content-muted)" }}>
                                <span style={{ display: "inline-flex", alignItems: "center", gap: 4 }}>
                                    <IconClock size={12}/> {c.timeAgo}
                                </span>
                                <a href="#" style={{ display: "inline-flex", alignItems: "center", gap: 4 }}>
                                    <IconArrowTopRightOnSquare size={12}/> 원문 보기
                                </a>
                            </div>
                        </Card>
                    ))}
                </div>
            </div>
            <div>
                <h3><IconHashtag size={18} className="rn-text-info"/> 태그</h3>
                <div style={{ display: "flex", flexWrap: "wrap", gap: 6 }}>
                    {["rails", "hotwire", "phlex", "postgres", "ai", "kamal"].map((t) => (
                        <Badge key={t} variant="neutral" size="sm" className="rn-pill" style={{ borderRadius: 9999, padding: "2px 10px" }}>
                            #{t}
                        </Badge>
                    ))}
                </div>
            </div>
        </aside>
    );
}

Object.assign(window, {
    Nav, Footer, Layout, ArticleCard, Comment, CommentForm,
    SummaryPanel, ProseCapsule, ArticleHeader, RecentCommentsSidebar,
});
