//
//  DeleteAccountView.swift
//  VexTrainer
//
//  Two-step deletion: this screen calls POST /Auth/delete-account/request,
//  which makes the server send the user an email with a confirmation
//  link. Clicking that link in the email goes to the web page which
//  calls /Auth/delete-account/confirm with the embedded token. The
//  app's job ends after the email request succeeds — we just tell the
//  user "check your inbox".
//

import SwiftUI

struct DeleteAccountView: View {

    let env: AppEnvironment
    let session: AuthSession

    @State private var vm: DeleteAccountViewModel
    @Environment(\.dismiss) private var dismiss

    init(env: AppEnvironment, session: AuthSession) {
        self.env = env
        self.session = session
        _vm = State(initialValue: DeleteAccountViewModel(
            authService: env.authService,
            email: session.email
        ))
    }

    var body: some View {
        ZStack {
            Color.vexNavy.ignoresSafeArea()
            content
        }
        .navigationTitle("Delete Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.vexNavy, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    @ViewBuilder
    private var content: some View {
        if vm.didSendSuccessfully {
            successView
        } else {
            confirmationView
        }
    }

    // MARK: - Confirmation (initial)

    private var confirmationView: some View {
        ScrollView {
            VStack(spacing: 20) {
                warningIcon
                warningHeadline
                whatHappensCard
                emailCard
                if let msg = vm.error {
                    InlineErrorBanner(message: msg)
                }
                sendButton
                cancelButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
    }

    private var warningIcon: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 52))
            .foregroundStyle(Color(red: 1.0, green: 0.5, blue: 0.5))
            .padding(.top, 16)
    }

    private var warningHeadline: some View {
        VStack(spacing: 6) {
            Text("This will permanently delete your account")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text("You'll receive a confirmation email with a link. The deletion only completes after you click that link.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var whatHappensCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHAT WILL BE DELETED")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))
                .tracking(0.5)
            bulletRow("Your VexTrainer profile and login")
            bulletRow("All quiz attempts and scores")
            bulletRow("Reading progress and streaks")
            bulletRow("Bookmarks")
            Text("This cannot be undone.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.55))
                .padding(.top, 4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func bulletRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white.opacity(0.4))
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
        }
    }

    private var emailCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("EMAIL WILL BE SENT TO")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))
                .tracking(0.5)
            HStack(spacing: 10) {
                Image(systemName: "envelope.fill")
                    .foregroundStyle(Color.vexCyan)
                Text(vm.email)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                Spacer()
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var sendButton: some View {
        Button {
            Task { await vm.sendDeletionEmail() }
        } label: {
            HStack(spacing: 8) {
                if vm.isSending {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Image(systemName: "envelope.badge.fill")
                }
                Text(vm.isSending ? "Sending…" : "Send Deletion Email")
                    .font(.body.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(red: 0.85, green: 0.25, blue: 0.25))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(vm.isSending)
        .padding(.top, 4)
    }

    private var cancelButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Cancel")
                .font(.body.weight(.medium))
                .foregroundStyle(.white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .disabled(vm.isSending)
    }

    // MARK: - Success (email sent)

    private var successView: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.vexCyan.opacity(0.15))
                    .frame(width: 92, height: 92)
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(Color.vexCyan)
            }
            VStack(spacing: 8) {
                Text("Check your email")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text("We sent a confirmation link to")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                Text(vm.email)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.top, 2)
                Text("Click the link in that email to complete deletion. The link expires in 24 hours.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 28)
            Spacer()
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.vexNavy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.vexOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
