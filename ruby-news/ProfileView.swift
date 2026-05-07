//
//  ProfileView.swift
//  ruby-news
//

import SwiftUI

struct ProfileView: View {
    @State private var sessionStore = SessionStore()

    var body: some View {
        NavigationStack {
            Group {
                if sessionStore.isLoading {
                    ProgressView("로딩 중")
                } else if sessionStore.isSignedIn {
                    signedInView
                } else {
                    signedOutView
                }
            }
            .navigationTitle("내 정보")
        }
        .task {
            await sessionStore.refresh()
        }
    }

    private var signedInView: some View {
        VStack(spacing: 16) {
            if let avatarURL = sessionStore.currentUser?.avatarURL {
                AsyncImage(url: avatarURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            }

            Text(sessionStore.currentUser?.name ?? "")
                .font(.headline)

            Text("@\(sessionStore.currentUser?.username ?? "")")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            NavigationLink {
                HotwireScreen(route: .profile(username: sessionStore.currentUser?.username ?? ""))
                    .ignoresSafeArea(edges: .bottom)
            } label: {
                Text("프로필 보기")
            }

            NavigationLink {
                HotwireScreen(route: .account)
                    .ignoresSafeArea(edges: .bottom)
            } label: {
                Text("계정 설정")
            }
        }
        .padding()
    }

    private var signedOutView: some View {
        VStack(spacing: 16) {
            Text("로그인이 필요합니다")
                .font(.headline)

            Text("로그인하면 좋아요, 피드, 프로필 등의 기능을 사용할 수 있습니다.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            NavigationLink {
                HotwireScreen(route: .login)
                    .ignoresSafeArea(edges: .bottom)
            } label: {
                Text("로그인")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            NavigationLink {
                HotwireScreen(route: .signup)
                    .ignoresSafeArea(edges: .bottom)
            } label: {
                Text("회원가입")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

#Preview {
    ProfileView()
}