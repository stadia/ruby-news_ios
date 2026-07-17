//
//  NewsSearchPage.swift
//  ruby-news
//
//  Created by JEFF.DEAN on 6/18/26.
//

import SwiftUI

struct NewsSearchPage: View {
    let title: String
    let onArticleSelected: (String) -> Void

    @State private var viewModel = NewsViewModel()
    @State private var isSearchPresented: Bool

    init(title: String, presentsSearchOnAppear: Bool, onArticleSelected: @escaping (String) -> Void) {
        self.title = title
        self.onArticleSelected = onArticleSelected
        _isSearchPresented = State(initialValue: presentsSearchOnAppear)
    }

    var body: some View {
        mainContent
            .searchable(
                text: $viewModel.searchQuery,
                isPresented: $isSearchPresented,
                placement: .toolbar,
                prompt: "뉴스 검색"
            )
            .searchToolbarBehavior(.minimize)
            .onSubmit(of: .search) {
                Task { await viewModel.search() }
            }
            .onChange(of: viewModel.searchQuery) { oldValue, newValue in
                guard !oldValue.isEmpty, newValue.isEmpty else { return }
                Task { await viewModel.search() }
            }
            .onAppear {
                isSearchPresented = true
                Task { await viewModel.load() }
            }
    }

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.isLoading && viewModel.articles.isEmpty {
            ProgressView("로딩 중...")
        } else if let errorMessage = viewModel.errorMessage, viewModel.articles.isEmpty {
            ContentUnavailableView {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
            } actions: {
                Button("다시 시도") {
                    Task { await viewModel.load() }
                }
            }
        } else if viewModel.articles.isEmpty {
            if !viewModel.searchQuery.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchQuery)
            } else {
                ContentUnavailableView {
                    Label("뉴스가 없습니다", systemImage: "newspaper")
                } description: {
                    Text("잠시 후 다시 시도해 주세요")
                }
            }
        } else {
            List {
                if let errorMessage = viewModel.errorMessage, !viewModel.articles.isEmpty {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                if let selectedTag = viewModel.selectedTag {
                    HStack {
                        Label("#\(selectedTag)", systemImage: "tag")
                        Spacer()
                        Button("해제") {
                            Task { await viewModel.clearTag() }
                        }
                    }
                    .font(.subheadline)
                }

                ForEach(viewModel.articles) { article in
                    NewsArticleRow(
                        article: article,
                        onTagSelected: { tag in
                            Task { await viewModel.selectTag(tag) }
                        },
                        onLikeTapped: {
                            Task { await viewModel.toggleLike(article) }
                        },
                        onBoostTapped: {
                            Task { await viewModel.toggleBoost(article) }
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onArticleSelected(article.id)
                    }
                    .onAppear {
                        Task { await viewModel.loadMoreIfNeeded(current: article) }
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
        }
    }
}
