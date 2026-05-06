//
//  FeedView.swift
//  ruby-news
//
//  Created by JEFF.DEAN on 5/6/26.
//

import SwiftUI

struct FeedView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "피드를 연결할 준비 중입니다",
                systemImage: "person.2",
                description: Text("초기 피드는 Hotwire Native로 /feed 화면을 연결합니다.")
            )
            .navigationTitle("피드")
        }
    }
}

#Preview {
    FeedView()
}
