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
                        ForEach(viewModel.articles) { article in
                            Button {
                                selectedArticle = article
                            } label: {
                                NewsArticleRow(article: article)
                            }
                            .buttonStyle(.plain)
                        }

                        if viewModel.isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else if viewModel.canLoadMore {
                            Button("더 보기") {
                                Task { await viewModel.loadMore() }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .refreshable {
                        await viewModel.load()
                    }
                }
            }
            .navigationTitle("뉴스")
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
