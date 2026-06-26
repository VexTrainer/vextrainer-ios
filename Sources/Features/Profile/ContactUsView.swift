//
//  ContactUsView.swift
//  VexTrainer
//
//  Profile → Contact Us. Read-only user identity card on top, three
//  category buttons (Suggestion/Correction/Other), multi-line message
//  field with character counter, and a Send button. On success: show
//  an inline confirmation and clear the message.
//

import SwiftUI

struct ContactUsView: View {

    let env: AppEnvironment
    let session: AuthSession

    @State private var vm: ContactUsViewModel
    @FocusState private var messageFocused: Bool

    init(env: AppEnvironment, session: AuthSession, initialMessage: String = "") {
        self.env = env
        self.session = session
        _vm = State(initialValue: ContactUsViewModel(
            service: env.contactService,
            initialMessage: initialMessage
        ))
    }

    var body: some View {
        ZStack {
            Color.vexNavy.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    userCard
                    categorySection
                    messageSection
                    if vm.didSendSuccessfully {
                        successBanner
                    }
                    if let msg = vm.error {
                        InlineErrorBanner(message: msg)
                    }
                    sendButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Contact Us")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.vexNavy, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            // Small delay before requesting focus — without it, the
            // NavigationStack push animation can race the keyboard
            // and the keyboard sometimes doesn't actually appear.
            // Same trick used by the fill-in-blank question view.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                messageFocused = true
            }
        }
    }

    // MARK: - User card

    private var userCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.userName.isEmpty ? "VexTrainer User" : session.userName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Text(session.email)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Category picker

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Subject")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))
                .tracking(0.5)
            HStack(spacing: 8) {
                ForEach(ContactUsViewModel.categories, id: \.self) { option in
                    categoryButton(option)
                }
            }
        }
    }

    private func categoryButton(_ option: String) -> some View {
        let selected = vm.category == option
        return Button {
            vm.category = option
        } label: {
            Text(option)
                .font(.subheadline.weight(selected ? .bold : .medium))
                .foregroundStyle(selected ? Color.vexNavy : .white.opacity(0.85))
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(selected ? Color.vexOrange : Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(selected ? Color.vexOrange : .white.opacity(0.15), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Message editor

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Message")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))
                .tracking(0.5)

            ZStack(alignment: .topLeading) {
                TextEditor(text: messageBinding)
                    .focused($messageFocused)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .foregroundStyle(.white)
                    .tint(Color.vexOrange)
                    .frame(minHeight: 160)

                if vm.message.isEmpty {
                    Text("Tell us what's on your mind…")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.35))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
            )

            HStack {
                if !vm.minimumContentHint.isEmpty {
                    Text(vm.minimumContentHint)
                        .font(.caption2)
                        .foregroundStyle(Color.vexOrange.opacity(0.85))
                }
                Spacer()
                Text(vm.characterCountLabel)
                    .font(.caption2)
                    .foregroundStyle(vm.isOverLimit ? Color(red: 1, green: 0.5, blue: 0.5) : .white.opacity(0.4))
                    .monospacedDigit()
            }
        }
    }

    /// Hard cap at maxMessageChars — additional keystrokes are dropped.
    private var messageBinding: Binding<String> {
        Binding(
            get: { vm.message },
            set: { newValue in
                if newValue.count <= ContactUsViewModel.maxMessageChars {
                    vm.message = newValue
                } else {
                    vm.message = String(newValue.prefix(ContactUsViewModel.maxMessageChars))
                }
                // Typing dismisses any prior success banner so user can
                // see the next outcome cleanly.
                if vm.didSendSuccessfully { vm.didSendSuccessfully = false }
            }
        )
    }

    // MARK: - Success

    private var successBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.vexGreen)
            Text("Message sent! We'll get back to you soon.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(12)
        .background(Color.vexGreen.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.vexGreen.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - Send

    private var sendButton: some View {
        PrimaryButton(
            "Send Message",
            isLoading: vm.isSending,
            isEnabled: vm.canSend,
            style: .filled
        ) {
            messageFocused = false
            Task { await vm.send() }
        }
        .padding(.top, 4)
    }
}
