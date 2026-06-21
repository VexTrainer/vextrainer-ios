//
//  RootView.swift
//  VexTrainer
//
//  Top-level switch on AppRouter.route. Everything substantive happens in the
//  child views — AuthFlow for sign-in/up, MainShellView (placeholder for now)
//  for the authenticated state, SplashView for the brief launch check.
//
//  Also owns the App Switcher cover overlay: when the app's scene transitions
//  out of .active (Home button, App Switcher invocation, control center, etc.),
//  AppSwitcherCoverView is rendered on top. iOS samples the topmost view to
//  populate the App Switcher thumbnail, so this prevents whatever the user was
//  doing (typing a support message, reading email, mid-quiz) from being baked
//  into the system screenshot.
//
//  The overlay deliberately does NOT animate. SwiftUI must apply the change
//  synchronously before iOS captures the snapshot; an animation here can lead
//  to a partially-faded cover in the snapshot. iOS's own foreground transition
//  animation handles the return-to-foreground experience.
//

import SwiftUI

struct RootView: View {

    @Environment(AppRouter.self) private var router
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch router.route {
            case .checking:
                SplashView()
            case .unauthenticated:
                AuthFlow()
            case .authenticated(let session):
                MainShellView(session: session)
            }
        }
        .preferredColorScheme(.dark)
        // Smooth crossfade when the route flips. Without this, the transition
        // between Splash → AuthFlow looks jarring.
        .animation(.easeInOut(duration: 0.25), value: routeKey)
        .overlay {
            // .active is the only "real" foreground state — everything else
            // (.inactive during transitions, .background while suspended)
            // gets the cover. Using `!=`  keeps us forward-compatible if
            // Apple adds a fourth case.
            if scenePhase != .active {
                AppSwitcherCoverView()
            }
        }
    }

    /// Equatable hash for the route, since associated values aren't directly
    /// usable as the `value:` of `.animation(_:value:)`.
    private var routeKey: Int {
        switch router.route {
        case .checking: 0
        case .unauthenticated: 1
        case .authenticated: 2
        }
    }
}
