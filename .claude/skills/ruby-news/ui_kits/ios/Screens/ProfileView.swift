// ProfileView.swift — 프로필 / 설정.

import SwiftUI

struct ProfileView: View {
    @State private var signedIn = false
    @State private var pushEnabled = true
    @State private var darkOnly = true
    @State private var bodyFontSize: Double = 15

    var body: some View {
        NavigationStack {
            ZStack {
                RNColor.bgApp.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: RNSpacing.lg) {
                        if signedIn {
                            profileCard
                        } else {
                            signedOutCard
                        }
                        settingsList
                        aboutBlock
                    }
                    .padding(RNSpacing.md)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("프로필")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var profileCard: some View {
        RNCard(padding: RNSpacing.lg) {
            HStack(spacing: RNSpacing.md) {
                RNAvatar(name: "news kr", size: 64)
                VStack(alignment: .leading, spacing: 2) {
                    Text("news_kr")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(RNColor.textContent)
                    Text("@news_kr@ruby.social")
                        .font(.system(size: 13))
                        .foregroundStyle(RNColor.textContentMuted)
                }
                Spacer()
                RNButton(title: "글 등록", variant: .primary, size: .sm) { }
                    .fixedSize()
            }
        }
    }

    private var signedOutCard: some View {
        RNCard(padding: RNSpacing.lg) {
            VStack(spacing: RNSpacing.sm) {
                Text("로그인하면 댓글 작성과 좋아요가 가능합니다")
                    .font(.system(size: 14))
                    .foregroundStyle(RNColor.textContentSecondary)
                    .multilineTextAlignment(.center)
                NavigationLink {
                    LoginView()
                } label: {
                    Text("로그인")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(RNColor.brandForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RNColor.brand)
                        .clipShape(RoundedRectangle(cornerRadius: RNRadius.md))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var settingsList: some View {
        VStack(alignment: .leading, spacing: RNSpacing.sm) {
            Text("설정")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(RNColor.textContentMuted)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                row {
                    Toggle(isOn: $pushEnabled) { settingLabel("푸시 알림", systemImage: "bell") }
                        .tint(RNColor.brand)
                }
                divider
                row {
                    Toggle(isOn: $darkOnly) { settingLabel("다크 모드 고정", systemImage: "moon") }
                        .tint(RNColor.brand)
                }
                divider
                row {
                    HStack {
                        settingLabel("기사 본문 폰트 크기", systemImage: "textformat.size")
                        Spacer()
                        Text("\(Int(bodyFontSize))pt")
                            .font(.system(size: 13))
                            .foregroundStyle(RNColor.textContentMuted)
                    }
                }
                Slider(value: $bodyFontSize, in: 13...22, step: 1)
                    .tint(RNColor.brand)
                    .padding(.horizontal, RNSpacing.md)
                    .padding(.bottom, RNSpacing.sm)
                divider
                row {
                    Link(destination: URL(string: "https://ruby-news.kr/feed.xml")!) {
                        HStack {
                            settingLabel("RSS 피드", systemImage: "dot.radiowaves.up.forward")
                            Spacer()
                            Image(systemName: "arrow.up.right.square").foregroundStyle(RNColor.textContentMuted)
                        }
                    }
                }
            }
            .background(RNColor.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: RNRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: RNRadius.lg, style: .continuous)
                    .strokeBorder(RNColor.borderStrong, lineWidth: 1)
            )
        }
    }

    private func row<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content().padding(.horizontal, RNSpacing.md).padding(.vertical, 12)
    }

    private var divider: some View {
        Rectangle().fill(RNColor.borderSubtle).frame(height: 1)
    }

    private func settingLabel(_ title: String, systemImage: String) -> some View {
        Label {
            Text(title).font(.system(size: 14)).foregroundStyle(RNColor.textContent)
        } icon: {
            Image(systemName: systemImage).foregroundStyle(RNColor.textContentMuted)
        }
    }

    private var aboutBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Ruby-News || 루비 AI 뉴스")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(RNColor.textContentSecondary)
            Text("© 2025 Ruby-News. All Rights Reserved.")
                .font(.system(size: 11))
                .foregroundStyle(RNColor.textContentMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, RNSpacing.md)
    }
}
