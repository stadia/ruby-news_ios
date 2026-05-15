//
//  SignedOutView.swift
//  ruby-news
//

import SwiftUI

struct SignedOutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("로그인이 필요합니다")
                .font(.headline)

            Text("로그인하면 좋아요, 피드 등의 기능을 사용할 수 있습니다.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            NavigationLink {
                NativeLoginView()
            } label: {
                Text("로그인")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            NavigationLink {
                HotwireScreen(route: .signup)
                    .ignoresSafeArea(edges: .bottom)
            } label: {
                Text("회원 가입")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
