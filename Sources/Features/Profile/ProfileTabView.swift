//
//  ProfileTabView.swift
//  VexTrainer
//
//  Profile tab. Account card + menu of:
//    • About Us            — pushes AboutView (markdown + version)
//    • Contact Us          — pushes ContactUsView (form)
//    • Privacy Policy      — pushes PrivacyPolicyView (markdown)
//    • Donate              — opens system browser (vextrainer.com/Donate)
//    • Delete My Account   — opens system browser (vextrainer.com/Auth/DeleteAccount)
//    • Log Out             — clears session, returns to login
//

import SwiftUI

struct ProfileTabView: View {

    @Environment(AppEnvironment.self) private var env
    @Environment(\.openURL) private var openURL

    let session: AuthSession
    @Binding var path: NavigationPath

    @State private var isLoggingOut = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.vexNavy.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        avatar
                        userCard
                        menuList
                        logoutButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.vexNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(for: ProfileRoute.self) { route in
                ProfileRouter.destination(for: route, env: env, session: session)
            }
        }
        .environment(\.appNavigationPath, $path)
    }

    // MARK: - Header

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(Color.vexOrange.opacity(0.15))
                .frame(width: 100, height: 100)
            Text(initials)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Color.vexOrange)
        }
        .padding(.top, 8)
    }

    private var initials: String {
        let parts = session.userName.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map(String.init)
        let joined = letters.joined().uppercased()
        return joined.isEmpty ? "?" : joined
    }

    private var userCard: some View {
        VStack(spacing: 6) {
            Text(session.userName.isEmpty ? "VexTrainer User" : session.userName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            Text(session.email)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: - Menu

    private var menuList: some View {
        VStack(spacing: 10) {
            NavigationLink(value: ProfileRoute.about) {
                ProfileMenuRow(
                    icon: "info.circle.fill",
                    title: "About Us",
                    iconTint: Color.vexCyan
                ) {
                    Text(appVersion)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .monospacedDigit()
                }
            }
            .buttonStyle(.plain)

            NavigationLink(value: ProfileRoute.contactUs) {
                ProfileMenuRow(
                    icon: "envelope.fill",
                    title: "Contact Us",
                    iconTint: Color.vexCyan
                )
            }
            .buttonStyle(.plain)

            NavigationLink(value: ProfileRoute.privacy) {
                ProfileMenuRow(
                    icon: "lock.shield.fill",
                    title: "Privacy Policy",
                    iconTint: Color.vexCyan
                )
            }
            .buttonStyle(.plain)

            Button {
                openURL(AppConfig.donateURL)
            } label: {
                ProfileMenuRow(
                    icon: "heart.fill",
                    title: "Donate",
                    iconTint: Color.vexOrange
                ) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .buttonStyle(.plain)

            NavigationLink(value: ProfileRoute.deleteAccount) {
                ProfileMenuRow(
                    icon: "trash.fill",
                    title: "Delete My Account",
                    iconTint: Color(red: 1.0, green: 0.5, blue: 0.5),
                    destructive: true
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var appVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return "v\(v ?? "—")"
    }

    // MARK: - Log out

    private var logoutButton: some View {
        PrimaryButton("Log Out", isLoading: isLoggingOut, isEnabled: !isLoggingOut, style: .outlined) {
            Task { await logout() }
        }
        .padding(.top, 8)
    }

    private func logout() async {
        isLoggingOut = true
        defer { isLoggingOut = false }
        try? await env.authService.logout()
        env.router.route = .unauthenticated
    }
}
