//
//  ProfileView.swift
//  ruby-news
//
//  Created by JEFF.DEAN on 5/6/26.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "로그인을 연결할 준비 중입니다",
                systemImage: "person.crop.circle",
                description: Text("Devise 웹 로그인과 쿠키 세션을 Hotwire Native로 연결합니다.")
            )
            .navigationTitle("내 정보")
        }
    }
}

#Preview {
    ProfileView()
}
