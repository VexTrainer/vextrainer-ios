//
//  RegisterView.swift
//  VexTrainer
//

import SwiftUI

struct RegisterView: View {

    @State private var vm: RegisterViewModel
    @Binding var path: NavigationPath

    @FocusState private var focusedField: Field?
    private enum Field { case userName, email, phone, password, confirmPassword }

    init(env: AppEnvironment, path: Binding<NavigationPath>, prefilledEmail: String = "") {
        _vm = State(initialValue: RegisterViewModel(
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
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.vexNavy.ignoresSafeArea())
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Form

    private var form: some View {
        VStack(spacing: 14) {
            Text("Create your VexTrainer account")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)

            TextField("Full name", text: $vm.userName)
                .textContentType(.name)
                .submitLabel(.next)
                .focused($focusedField, equals: .userName)
                .onSubmit { focusedField = .email }
                .onChange(of: vm.userName) { _, _ in vm.clearErrorOnEdit() }
                .vexFieldStyle()

            TextField("Email", text: $vm.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.next)
                .focused($focusedField, equals: .email)
                .onSubmit { focusedField = .phone }
                .onChange(of: vm.email) { _, _ in vm.clearErrorOnEdit() }
                .vexFieldStyle()

            TextField("Phone (optional)", text: $vm.phone)
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)
                .submitLabel(.next)
                .focused($focusedField, equals: .phone)
                .onSubmit { focusedField = .password }
                .onChange(of: vm.phone) { _, _ in vm.clearErrorOnEdit() }
                .vexFieldStyle()

            PasswordField(
                placeholder: "Password (8+ characters)",
                text: $vm.password,
                contentType: .newPassword,
                onSubmit: { focusedField = .confirmPassword }
            )
            .focused($focusedField, equals: .password)
            .onChange(of: vm.password) { _, _ in vm.clearErrorOnEdit() }

            PasswordField(
                placeholder: "Confirm password",
                text: $vm.confirmPassword,
                contentType: .newPassword,
                onSubmit: { Task { await vm.submit() } }
            )
            .focused($focusedField, equals: .confirmPassword)
            .onChange(of: vm.confirmPassword) { _, _ in vm.clearErrorOnEdit() }

            if !vm.confirmPassword.isEmpty, !vm.passwordsMatch {
                Text("Passwords don't match")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            InlineErrorBanner(message: vm.errorMessage)

            PrimaryButton(
                "Create Account",
                isLoading: vm.isSubmitting,
                isEnabled: vm.canSubmit
            ) {
                focusedField = nil
                Task { await vm.submit() }
            }
        }
    }

    // MARK: - Success state

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

                Text("We sent an activation link to \(vm.email). Open it in your browser to activate your account, then come back here to sign in.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            PrimaryButton("Back to Sign In") {
                // Pop to root regardless of how deep we are.
                path = NavigationPath()
            }
            .padding(.top, 20)
        }
        .padding(.horizontal, 8)
    }
}
