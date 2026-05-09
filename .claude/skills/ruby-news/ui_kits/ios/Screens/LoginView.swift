// LoginView.swift — 로그인 / 회원 가입.
// HIG modal-style sheet with Ruby-News tokens.

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var staySignedIn = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            RNColor.bgApp.ignoresSafeArea()

            VStack(spacing: RNSpacing.md) {
                VStack(spacing: 4) {
                    Text("로그인")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(RNColor.textContent)
                    Text("Ruby-News 계정으로 로그인하세요")
                        .font(.system(size: 13))
                        .foregroundStyle(RNColor.textContentMuted)
                }
                .frame(maxWidth: .infinity)

                RNCard(padding: RNSpacing.lg) {
                    VStack(spacing: RNSpacing.md) {
                        RNField(label: "이메일") {
                            RNTextField(placeholder: "you@example.com", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        RNField(label: "비밀번호") {
                            RNTextField(placeholder: "••••••••", text: $password, isSecure: true)
                                .textContentType(.password)
                        }
                        HStack {
                            Toggle(isOn: $staySignedIn) {
                                Text("로그인 상태 유지").font(.system(size: 13))
                            }
                            .toggleStyle(.switch)
                            .tint(RNColor.brand)
                            Spacer()
                            Button("비밀번호 찾기") { }
                                .font(.system(size: 13))
                                .foregroundStyle(RNColor.accentText)
                        }
                        RNButton(title: "로그인", variant: .primary, size: .lg) {
                            // submit
                        }
                        HStack(spacing: 4) {
                            Text("계정이 없으신가요?")
                                .font(.system(size: 13))
                                .foregroundStyle(RNColor.textContentMuted)
                            Button("회원 가입") { }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(RNColor.accentText)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: 440)

                Spacer()
            }
            .padding(RNSpacing.md)
            .padding(.top, RNSpacing.xl)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
