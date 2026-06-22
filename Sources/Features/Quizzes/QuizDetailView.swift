//
//  QuizDetailView.swift
//  VexTrainer
//
//  Full quiz detail screen — pushed when the user taps a quiz card in a
//  multi-quiz list. When a subcategory has only one quiz, QuizListView
//  short-circuits and renders QuizDetailContentView directly (no separate
//  push), keeping the subcategory name as the title.
//

import SwiftUI

struct QuizDetailView: View {

    @Environment(AppEnvironment.self) private var env

    let quiz: QuizSummary
    let categoryName: String

    var body: some View {
        ZStack {
            Color.vexNavy.ignoresSafeArea()
            QuizDetailContentView(env: env, quiz: quiz, categoryName: categoryName)
        }
        .navigationTitle(quiz.quizTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.vexNavy, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}
