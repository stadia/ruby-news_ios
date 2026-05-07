//
//  NewsView.swift
//  ruby-news
//
//  Created by JEFF.DEAN on 5/6/26.
//

import SwiftUI

struct NewsView: View {
    @State private var viewModel = NewsViewModel()
    @State private var selectedArticle: NewsArticle?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.articles.isEmpty {
                    ProgressView("뉴스를 불러오는 중입니다")
                } else if let errorMessage = viewModel.errorMessage, viewModel.articles.isEmpty {
                    ContentUnavailableView {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                    } actions: {
                        Button("다시 시도") {
                            Task { await viewModel.load() }
                        }
                    }
                } else {
                    List {
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
                                selectedArticle = article
                            })
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedArticle = article
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
                    .refreshable {
                        await viewModel.load()
                    }
                }
            }
            .navigationTitle("뉴스")
            .searchable(text: $viewModel.searchQuery, prompt: "뉴스 검색")
            .onSubmit(of: .search) {
                Task { await viewModel.search() }
            }
            .onChange(of: viewModel.searchQuery) { oldValue, newValue in
                guard !oldValue.isEmpty, newValue.isEmpty else { return }
                Task { await viewModel.search() }
            }
            .task {
                guard viewModel.articles.isEmpty else { return }
                await viewModel.load()
            }
            .sheet(item: $selectedArticle) { article in
                NavigationStack {
                    HotwireScreen(route: .article(id: article.id))
                        .ignoresSafeArea(edges: .bottom)
                        .navigationTitle(article.displayTitle)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("닫기") {
                                    selectedArticle = nil
                                }
                            }
                        }
                }
            }
        }
    }
}

#Preview {
    NewsView()
}
