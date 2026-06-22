//
//  QuizDTOs.swift
//  VexTrainer
//

import Foundation

// MARK: - Categories (hierarchical, paged)

/// Categories form a tree. Top-level (parent) categories have
/// `parentCategoryId == nil`. Each parent ships with its `subcategories`
/// inline — the paged endpoint returns the full subtree for each parent in
/// the page, so we never need a separate fetch for subcategories.
///
/// Leaves have `subcategories: null` and are the only categories that
/// contain quizzes.
struct QuizCategory: Decodable, Sendable, Identifiable, Hashable {
    let categoryId: Int
    let parentCategoryId: Int?
    let categoryName: String
    let displayOrder: Int
    let subcategories: [QuizCategory]?

    var id: Int { categoryId }

    var isLeaf: Bool { (subcategories ?? []).isEmpty }
    var subcategoryCount: Int { subcategories?.count ?? 0 }
}

/// Envelope for `GET /Quiz/categories/paged?offset=N&pageSize=M`.
struct PagedCategoriesResponse: Decodable, Sendable {
    let categories: [QuizCategory]
    let hasMore: Bool
}

// MARK: - Quiz summary
//
// Real server response for `GET /Quiz/categories/{id}/quizzes`:
//   {
//     "quizId": 1,
//     "quizTitle": "0.1 - The V5 Brain",
//     "quizDescription": null,
//     "totalQuestions": 11,
//     "passingScore": null,
//     "displayOrder": 1,
//     "userAttempts": 4,
//     "userBestScore": 0.00,
//     "isCompleted": true
//   }

struct QuizSummary: Decodable, Sendable, Identifiable, Hashable {
    let quizId: Int
    let quizTitle: String
    /// Always null in the live data — kept for future-proofing, never shown.
    let quizDescription: String?
    let totalQuestions: Int
    /// Server can return null. We only show this when non-null and > 0.
    let passingScore: Double?
    let displayOrder: Int
    let userAttempts: Int
    /// Null when the user hasn't attempted the quiz. Server returns 0.00 (not
    /// null) when there ARE attempts but the best was a zero — we treat both
    /// the same way at the call site.
    let userBestScore: Double?
    let isCompleted: Bool

    var id: Int { quizId }
}

// MARK: - Quiz detail (single quiz fetch)

/// Response for `GET /Quiz/quizzes/{id}`. Used when entering the detail
/// screen with only a quiz ID in hand (cross-tab navigation from the
/// Activity Report). Carries the same fields as QuizSummary plus the
/// owning category's name, which the detail screen displays as a chip.
///
/// Note: the live server response omits `isCompleted` and `displayOrder`
/// for this endpoint (unlike `/Quiz/categories/{id}/quizzes`). Both are
/// declared optional here and defaulted in `asSummary`:
///   - displayOrder → 0 (only used for list sorting, irrelevant here)
///   - isCompleted  → derived from `userBestScore != nil` (the server's
///     own convention: a recorded best score means at least one
///     completed attempt; null means no completed attempt)
struct QuizDetailDto: Decodable, Sendable {
    let quizId: Int
    let quizTitle: String
    let quizDescription: String?
    let totalQuestions: Int
    let passingScore: Double?
    let displayOrder: Int?
    let userAttempts: Int
    let userBestScore: Double?
    let isCompleted: Bool?
    let categoryName: String

    var asSummary: QuizSummary {
        QuizSummary(
            quizId: quizId,
            quizTitle: quizTitle,
            quizDescription: quizDescription,
            totalQuestions: totalQuestions,
            passingScore: passingScore,
            displayOrder: displayOrder ?? 0,
            userAttempts: userAttempts,
            userBestScore: userBestScore,
            isCompleted: isCompleted ?? (userBestScore != nil)
        )
    }
}
