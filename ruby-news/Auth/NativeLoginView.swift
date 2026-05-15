//
//  NativeLoginView.swift
//  ruby-news
//

import Observation
import SwiftUI

struct NativeLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var sessionStore

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                TextField("이메일", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .textContentType(.username)

                SecureField("비밀번호", text: $password)
                    .textContentType(.password)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    Task {
                        await submit()
                    }
                } label: {
                    if sessionStore.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("로그인")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isSubmitDisabled)
            }
        }
        .navigationTitle("로그인")
    }

    private var isSubmitDisabled: Bool {
        email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        password.isEmpty ||
        sessionStore.isLoading
    }

    @MainActor
    private func submit() async {
        errorMessage = nil

        do {
            try await sessionStore.login(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            dismiss()
        } catch APIError.unacceptableStatusCode(401) {
            errorMessage = "이메일 또는 비밀번호를 확인해 주세요."
        } catch {
            errorMessage = "로그인에 실패했습니다. 다시 시도해 주세요."
        }
    }
}

#Preview {
    NavigationStack {
        NativeLoginView()
            .environment(SessionStore(
                fetchCurrentUser: {
                    CurrentUser(id: 1, email: "jeff@example.com", name: "Jeff", username: "jeff", avatarURL: nil)
                }
            ))
    }
}
