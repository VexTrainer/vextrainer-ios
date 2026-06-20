//
//  ForgotPasswordView.swift
//  VexTrainer
//

import SwiftUI

struct ForgotPasswordView: View {

    @State private var vm: ForgotPasswordViewModel
    @Binding var path: NavigationPath

    @FocusState private var emailFocused: Bool

    init(env: AppEnvironment, path: Binding<NavigationPath>, prefilledEmail: String = "") {
        _vm = State(initialValue: ForgotPasswordViewModel(
            authService: env.authService,
            prefilledEmail: prefilledEmail
        ))
        _path = path
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if vm.didSucceed {
                    successState
                } else {
                    form
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 32)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.vexNavy.ignoresSafeArea())
        .navigationTitle("Forgot Password")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var form: some View {
        VStack(spacing: 14) {
            Text("Enter the email associated with your account and we'll send you a link to reset your password.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)

            TextField("Email", text: $vm.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.go)
                .focused($emailFocused)
                .onSubmit { Task { await vm.submit() } }
                .onChange(of: vm.email) { _, _ in vm.clearErrorOnEdit() }
                .vexFieldStyle()

            InlineErrorBanner(message: vm.errorMessage)

            PrimaryButton(
                "Send Reset Link",
                isLoading: vm.isSubmitting,
                isEnabled: vm.canSubmit
            ) {
                emailFocused = false
                Task { await vm.submit() }
            }
        }
    }

    private var successState: some View {
        VStack(spacing: 24) {
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.vexGreen)
                .padding(.top, 40)

            VStack(spacing: 12) {
                Text("Check your inbox")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text("We sent a password reset link to \(vm.email). Open it in your browser to set a new password, then come back here to sign in.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            PrimaryButton("Back to Sign In") {
                path = NavigationPath()
            }
            .padding(.top, 20)
        }
        .padding(.horizontal, 8)
    }
}
