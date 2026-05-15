//
//  NewsView.swift
//  ruby-news
//
//  Created by JEFF.DEAN on 5/6/26.
//

import SwiftUI

struct NewsView: View {
    @State private var viewModel = NewsViewModel()
    @State private var isSearchPresented: Bool

    private let title: String
    private let showsSearch: Bool
    private let presentsSearchOnAppear: Bool
    private let onArticleSelected: (String) -> Void

    init(
        title: String = "뉴스",
        showsSearch: Bool = false,
        presentsSearchOnAppear: Bool = false,
        onArticleSelected: @escaping (String) -> Void = { _ in }
    ) {
        self.title = title
        self.showsSearch = showsSearch
        self.presentsSearchOnAppear = presentsSearchOnAppear
        self.onArticleSelected = onArticleSelected
        _isSearchPresented = State(initialValue: presentsSearchOnAppear)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if !showsSearch {
                        ToolbarItem(placement: .principal) {
                            Picker("", selection: Binding(
                                get: { viewModel.source },
                                set: { source in Task { await viewModel.selectSource(source) } }
                            )) {
                                ForEach(NewsSource.allCases, id: \.self) { source in
                                    Text(source.label).tag(source)
                                }
                            }
                            .pickerStyle(.segmented)
                            .fixedSize()
                        }
                    }
                }
                .onAppear {
                    if showsSearch && presentsSearchOnAppear {
                        isSearchPresented = true
                    }
                    Task { await viewModel.load() }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if showsSearch {
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
        } else {
            mainContent
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
                    NewsArticleRow(article: article, onTagSelected: { tag in
                        Task { await viewModel.selectTag(tag) }
                    }, onLikeTapped: {
                        Task { await viewModel.toggleLike(article) }
                    })
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

#Preview {
    NewsView()
}
