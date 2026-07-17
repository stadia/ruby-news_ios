//
//  FeedView.swift
//  ruby-news
//

import SwiftUI

struct FeedView: View {
    @Environment(SessionStore.self) private var sessionStore
    @State private var viewModel = FeedViewModel()
    @State private var sheetRoute: FeedSheetRoute?
    @State private var safariLink: SafariLink?
    @State private var isComposePresented = false

    var body: some View {
        Group {
            if sessionStore.isLoading && !sessionStore.isSignedIn {
                ProgressView("로딩 중...")
            } else if sessionStore.isSignedIn {
                nativeFeed
            } else {
                NavigationStack {
                    SignedOutView()
                        .navigationTitle("피드")
                }
            }
        }
        .sheet(item: $sheetRoute) { route in
            HotwireScreen(route: route.webRoute)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var nativeFeed: some View {
        NavigationStack {
            content
                .navigationTitle("피드")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            isComposePresented = true
                        } label: {
                            Label("새 글", systemImage: "square.and.pencil")
                        }
                    }
                }
        }
        .sheet(isPresented: $isComposePresented) {
            FeedComposerView(onSubmitted: refreshFeed)
        }
        .task {
            guard viewModel.posts.isEmpty else { return }
            await viewModel.load()
        }
    }

    private func refreshFeed() {
        Task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.posts.isEmpty {
            ProgressView("피드를 불러오는 중...")
        } else if let errorMessage = viewModel.errorMessage, viewModel.posts.isEmpty {
            ContentUnavailableView {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
            } actions: {
                Button("다시 시도") {
                    Task { await viewModel.load() }
                }
            }
        } else if viewModel.posts.isEmpty {
            ContentUnavailableView {
                Label("새 피드가 없습니다", systemImage: "text.bubble")
            } description: {
                Text("팔로우한 사용자의 새 소식이 여기에 표시됩니다.")
            }
        } else {
            List {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                ForEach(viewModel.posts) { post in
                    FeedPostRow(
                        post: post,
                        onSelected: {
                            guard let slug = post.slug, !slug.isEmpty else { return }
                            sheetRoute = .post(slug)
                        },
                        onLikeTapped: {
                            Task { await viewModel.toggleLike(post) }
                        },
                        onBoostTapped: {
                            Task { await viewModel.toggleBoost(post) }
                        }
                    )
                    .onAppear {
                        Task { await viewModel.loadMoreIfNeeded(current: post) }
                    }
                }

                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.load()
            }
            .environment(
                \.openURL,
                OpenURLAction { url in
                    guard url.scheme == "http" || url.scheme == "https" else {
                        return .systemAction
                    }
                    safariLink = SafariLink(url: url)
                    return .handled
                }
            )
            .sheet(item: $safariLink) { link in
                SafariView(url: link.url)
                    .ignoresSafeArea()
            }
        }
    }
}

private enum FeedSheetRoute: Identifiable {
    case post(String)

    var id: String {
        switch self {
        case .post(let slug):
            "post-\(slug)"
        }
    }

    var webRoute: WebRoute {
        switch self {
        case .post(let slug):
            .post(id: slug)
        }
    }
}

private struct SafariLink: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

#Preview {
    FeedView()
        .environment(SessionStore())
}
