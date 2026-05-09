//
//  ProfileView.swift
//  ruby-news
//

import SDWebImageSwiftUI
import SwiftUI

struct ProfileView: View {
    @State private var sessionStore = SessionStore()

    var body: some View {
        NavigationStack {
            Group {
                if sessionStore.isLoading {
                    ProgressView("로딩 중...")
                } else if sessionStore.isSignedIn {
                    signedInView
                } else {
                    signedOutView
                }
            }
            .navigationTitle("내 정보")
        }
        .onAppear {
            sessionStore.restoreSession()
            Task { @MainActor in
                await sessionStore.refresh()
            }
        }
    }

    private var signedInView: some View {
        VStack(spacing: 16) {
            if let avatarURL = sessionStore.currentUser?.avatarURL {
                WebImage(url: avatarURL) { image in
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
                Text("프로필")
            }

            NavigationLink {
                HotwireScreen(route: .account)
                    .ignoresSafeArea(edges: .bottom)
            } label: {
                Text("설정")
            }

            Button {
                Task { @MainActor in
                    await sessionStore.logout()
                }
            } label: {
                if sessionStore.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("로그아웃")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .disabled(sessionStore.isLoading)
        }
        .padding()
    }

    private var signedOutView: some View {
        SignedOutView(sessionStore: sessionStore)
    }
}

#Preview {
    ProfileView()
}