//
//  QuizHistoryDTOs.swift
//  VexTrainer
//
//  Wire types for GET /User/history?page=N&limit=N. Server stored proc
//  aliases all column names to camelCase, so plain Decodable works
//  without coding-key overrides.
//
//  startedDate / completedDate look like "2026-05-21T11:04:57.1666667"
//  (UTC, no Z). The first 19 chars are stable ISO date+time; sub-second
//  precision is dropped at render time. completedDate is null when the
//  attempt was abandoned mid-quiz. score is null in the same case (and
//  also legitimately 0.00 when the user completed but got everything
//  wrong — the server returns 0 in that case, not null).
//

import Foundation

struct QuizHistoryItem: Decodable, Sendable, Identifiable, Hashable {
    let attemptId: Int
    let quizId: Int
    let quizTitle: String
    let categoryName: String
    let startedDate: String
    let completedDate: String?
    let score: Double?
    let isCompleted: Bool

    var id: Int { attemptId }
}

struct QuizHistoryResponse: Decodable, Sendable {
    let attempts: [QuizHistoryItem]
    let totalCount: Int
    let page: Int
    let pageSize: Int
}
