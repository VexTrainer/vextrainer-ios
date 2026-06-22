//
//  QuizSessionDTOs.swift
//  VexTrainer
//
//  All wire-format types for the quiz session flow:
//  start → fetch questions → submit each answer → complete → results.
//

import Foundation

// MARK: - Start quiz

/// POST /Quiz/quizzes/{quizId}/start
struct StartQuizResponse: Decodable, Sendable, Hashable, Identifiable {
    let attemptId: Int
    let quizId: Int
    let startedDate: String
    let totalQuestions: Int

    var id: Int { attemptId }
}

// MARK: - Questions

/// One answer option. matchSide is "L"/"R" for matching questions, nil otherwise.
struct QuizAnswer: Decodable, Sendable, Identifiable, Hashable {
    let answerId: Int
    let questionId: Int
    let answerText: String
    let answerImagePath: String?
    let matchSide: String?

    var id: Int { answerId }
}

/// One question with all its answer options.
///
/// questionTypeId mapping (from server's sp_GetQuizQuestions):
///   1 = single answer (radio)
///   2 = multiple answer (checkbox)
///   3 = fill-in-blank (free text)
///   4 = true/false OR matching (disambiguated by matchSide on answers)
struct QuizQuestion: Decodable, Sendable, Identifiable, Hashable {
    let questionId: Int
    let questionTypeId: Int
    let questionType: String
    let questionText: String
    let questionImagePath: String?
    let pointValue: Double
    let answers: [QuizAnswer]

    var id: Int { questionId }

    /// Matching detection — any answer with a non-null matchSide overrides
    /// the questionTypeId interpretation. This is the robust way per Android.
    var isMatching: Bool {
        answers.contains { $0.matchSide != nil }
    }

    var kind: QuizQuestionKind {
        if isMatching { return .matching }
        switch questionTypeId {
        case 1: return .singleAnswer
        case 2: return .multipleAnswer
        case 3: return .fillInBlank
        case 4: return .trueFalse
        default: return .singleAnswer  // safe default
        }
    }
}

enum QuizQuestionKind: Sendable {
    case singleAnswer
    case multipleAnswer
    case fillInBlank
    case trueFalse
    case matching
}

/// GET /Quiz/attempts/{attemptId}/questions
struct QuizQuestionsResponse: Decodable, Sendable {
    let attemptId: Int
    let questions: [QuizQuestion]
}

// MARK: - Submit answer

/// POST /Quiz/attempts/{attemptId}/answer
///
/// answerJson formats (confirmed from Android live testing):
///   Single:     {"answerId":1}
///   Multi:      {"answerIds":[1,2,3]}      [PENDING_VERIFY — Android comments]
///   Fill-blank: {"text":"<typed>"}         [PENDING_VERIFY]
///   Matching:   {"pairs":[{"leftId":1,"rightId":4}, ...]} [PENDING_VERIFY]
///   T/F:        same as Single (just one of the two answers)
///
/// AnswerJSONBuilder constructs these — never inline.
struct SubmitAnswerRequest: Encodable, Sendable {
    let questionId: Int
    let answerJson: String
}

struct SubmitAnswerResponse: Decodable, Sendable {
    let isCorrect: Bool
    let explanation: String?
    /// Raw JSON string using snake_case keys, e.g. `{"answer_id":4306}` or
    /// `[{"answer_id":1},{"answer_id":2}]`. Parsed at the UI layer only when
    /// needed for "which option was correct" highlighting.
    let correctAnswerJson: String?
    let currentScore: Double
    let questionsAnswered: Int
}

// MARK: - Complete quiz

/// POST /Quiz/attempts/{attemptId}/complete
struct CompleteQuizResponse: Decodable, Sendable, Hashable, Identifiable {
    let attemptId: Int
    let finalScore: Double
    let correctAnswers: Int
    let totalQuestions: Int
    let passingScore: Double?
    let passed: Bool
    let completedDate: String

    var id: Int { attemptId }
}

// MARK: - Results

struct QuizResultSummary: Decodable, Sendable {
    let attemptId: Int
    let quizTitle: String
    let startedDate: String
    let completedDate: String?
    let score: Double?
    let correctAnswers: Int
    let totalQuestions: Int
    let passingScore: Double?
    let passed: Bool
}

struct QuestionResult: Decodable, Sendable, Identifiable {
    let questionId: Int
    let questionText: String
    let questionImagePath: String?
    let questionType: String
    let userAnswerJson: String?
    let isCorrect: Bool
    let explanation: String?
    /// Raw JSON string with the correct answer(s) — same snake_case format
    /// as SubmitAnswerResponse.correctAnswerJson.
    let correctAnswers: String?

    var id: Int { questionId }
}

/// GET /Quiz/attempts/{attemptId}/results
struct QuizResults: Decodable, Sendable {
    let summary: QuizResultSummary
    let questions: [QuestionResult]
}
