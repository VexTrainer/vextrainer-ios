//
//  VexTrainerApp.swift
//  VexTrainer
//

import SwiftUI

@main
struct VexTrainerApp: App {

    @State private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
                .environment(environment.router)
                .task {
                    await environment.bootstrap()
                }
        }
    }
}
