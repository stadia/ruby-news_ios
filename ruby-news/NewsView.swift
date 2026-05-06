//
//  NewsView.swift
//  ruby-news
//
//  Created by JEFF.DEAN on 5/6/26.
//

import SwiftUI

struct NewsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "뉴스를 불러올 준비 중입니다",
                systemImage: "newspaper",
                description: Text("ruby-news.kr의 JSON 응답이 준비되면 최신 Ruby 뉴스를 표시합니다.")
            )
            .navigationTitle("뉴스")
        }
    }
}

#Preview {
    NewsView()
}
