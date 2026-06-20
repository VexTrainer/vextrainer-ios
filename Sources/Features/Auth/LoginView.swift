//
//  LoginView.swift
//  VexTrainer
//
//  Two-step flow:
//    1. Email-only — Sign In is shown as an outlined button alongside
//       Forgot Password / Sign Up links. All three are equal-weight options.
//    2. Tapping Sign In reveals the password field below the email field
//       and morphs the Sign In button into a filled primary CTA.
//

import SwiftUI

struct LoginView: View {

    @State private var vm: LoginViewModel
    @Binding var path: NavigationPath
    let onContactTap: () -> Void

    @Environment(\.openURL) private var openURL

    @FocusState private var focusedField: Field?
    private enum Field { case email, password }

    @State private var isPasswordRevealed = false
    @State private var hasAutoFocused = false

    init(
        env: AppEnvironment,
        router: AppRouter,
        path: Binding<NavigationPath>,
        onContactTap: @escaping () -> Void
    ) {
        _vm = State(initialValue: LoginViewModel(authService: env.authService, router: router))
        _path = path
        self.onContactTap = onContactTap
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                form
                Spacer().frame(height: 8)
                signUpFooter
                Spacer().frame(height: 24)
                infoLinksFooter
            }
            .padding(.horizontal, 28)
            .padding(.top, 40)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.vexNavy.ignoresSafeArea())
        .task {
            // Auto-focus the email field on first appear. Guard so we don't
            // re-focus after the user comes back from Forgot/Register.
            guard !hasAutoFocused else { return }
            hasAutoFocused = true
            // Tiny delay — without it, the keyboard sometimes opens, then
            // immediately dismisses while NavigationStack settles.
            try? await Task.sleep(nanoseconds: 250_000_000)
            focusedField = .email
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 16) {
            Image("LogoVexTrainer")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Text("Welcome back")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text("Sign in to continue your curriculum")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.bottom, 8)
    }

    // MARK: - Form

    private var form: some View {
        VStack(spacing: 14) {
            TextField("Email", text: $vm.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(isPasswordRevealed ? .next : .go)
                .focused($focusedField, equals: .email)
                .onSubmit { onEmailReturn() }
                .onChange(of: vm.email) { _, _ in vm.clearErrorOnEdit() }
                .vexFieldStyle()

            if isPasswordRevealed {
                PasswordField(
                    placeholder: "Password",
                    text: $vm.password,
                    onSubmit: { Task { await submitOrReveal() } }
                )
                .focused($focusedField, equals: .password)
                .onChange(of: vm.password) { _, _ in vm.clearErrorOnEdit() }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            InlineErrorBanner(message: vm.errorMessage)

            PrimaryButton(
                "Sign In",
                isLoading: vm.isSubmitting,
                isEnabled: isPasswordRevealed ? vm.canSubmit : vm.isEmailValid,
                style: isPasswordRevealed ? .filled : .outlined
            ) {
                Task { await submitOrReveal() }
            }

            forgotPasswordRow
        }
    }

    private var forgotPasswordRow: some View {
        HStack {
            Spacer()
            Button("Forgot password?") {
                focusedField = nil
                path.append(AuthRoute.forgotPassword(prefilledEmail: vm.email))
            }
            .font(.footnote)
            .foregroundStyle(Color.vexCyan)
            .disabled(!vm.isEmailValid)
            .opacity(vm.isEmailValid ? 1 : 0.4)
        }
    }

    // MARK: - Sign up footer

    private var signUpFooter: some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .foregroundStyle(.white.opacity(0.6))
            Button("Sign up") {
                focusedField = nil
                path.append(AuthRoute.register(prefilledEmail: vm.email))
            }
            .foregroundStyle(Color.vexOrange)
            .fontWeight(.semibold)
            .disabled(!vm.isEmailValid)
            .opacity(vm.isEmailValid ? 1 : 0.4)
        }
        .font(.subheadline)
        .overlay(alignment: .bottom) {
            if !vm.isEmailValid {
                Text("Enter your email above to continue")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
                    .offset(y: 18)
            }
        }
    }

    // MARK: - Pre-login info links

    /// Four small text links at the bottom of the sign-in screen,
    /// separated by dot bullets:
    ///   About · Privacy · Donate · Contact
    /// About and Privacy push their respective views onto the AuthFlow
    /// NavigationStack (back arrow returns here). Donate opens the
    /// marketing site in Safari. Contact opens a mailto: composer to
    /// AppConfig.supportEmail — no JWT required, no server change.
    private var infoLinksFooter: some View {
        HStack(spacing: 0) {
            infoLink("About") { path.append(AuthRoute.about) }
            dotSeparator
            infoLink("Privacy") { path.append(AuthRoute.privacy) }
            dotSeparator
            infoLink("Donate") { openURL(AppConfig.donateURL) }
            dotSeparator
            infoLink("Contact") { onContactTap() }
        }
        .font(.footnote)
        .foregroundStyle(.white.opacity(0.55))
    }

    private func infoLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            focusedField = nil
            action()
        }) {
            Text(title)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    private var dotSeparator: some View {
        Text("·")
            .foregroundStyle(.white.opacity(0.25))
    }

    // MARK: - Actions

    private func onEmailReturn() {
        if !isPasswordRevealed {
            Task { await submitOrReveal() }
        } else {
            focusedField = .password
        }
    }

    private func submitOrReveal() async {
        if isPasswordRevealed {
            focusedField = nil
            await vm.submit()
        } else {
            guard vm.isEmailValid else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                isPasswordRevealed = true
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
            focusedField = .password
        }
    }
}
