//
//  QuizSessionViewModel.swift
//  VexTrainer
//
//  Mirror of the Android session view model. Phases:
//
//    loading
//      ↓ fetchQuestions success
//    questionDisplayed
//      ↓ user makes a selection
//    answerSelected
//      ↓ tap Submit
//    submitting
//      ↓ submitAnswer success
//    answerRevealed   (feedback card + correct-answer highlighting)
//      ↓ tap Next
//      → next question (back to questionDisplayed) OR completing → results
//

import Foundation
import Observation

@Observable
@MainActor
final class QuizSessionViewModel {

    enum Phase {
        case loading
        case questionDisplayed
        case answerSelected
        case submitting
        case answerRevealed
        case completing
        case error
    }

    // Phase
    var phase: Phase = .loading

    // Questions + position
    var questions: [QuizQuestion] = []
    var currentIndex: Int = 0

    // Single / multi selection (answerIds)
    var selectedAnswerIds: [Int] = []

    // Fill-in-blank typed answer
    var fillInBlankText: String = ""

    // Matching state
    var matchingPairs: [(leftId: Int, rightId: Int)] = []
    var selectedLeftId: Int?

    // After submit
    var answerResult: SubmitAnswerResponse?

    // Running counters
    var questionsAnswered: Int = 0
    var currentScore: Double = 0.0

    // Completion result for the navigation-to-results push.
    var completedResult: CompleteQuizResponse?

    var error: String?

    let attemptId: Int
    private let service: QuizServicing

    init(attemptId: Int, service: QuizServicing) {
        self.attemptId = attemptId
        self.service = service
    }

    // MARK: - Computed

    var currentQuestion: QuizQuestion? {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : nil
    }

    var totalQuestions: Int { questions.count }
    var isLastQuestion: Bool { currentIndex >= questions.count - 1 }
    var progressDisplay: Int { currentIndex + 1 }

    /// All left-side items in a matching question have a paired right item.
    var matchingComplete: Bool {
        guard let q = currentQuestion else { return false }
        let leftCount = q.answers.filter { $0.matchSide == "L" }.count
        return matchingPairs.count >= leftCount && leftCount > 0
    }

    /// Whether the Submit button should be enabled (call site can also gate
    /// on phase, but this captures the per-question-type rule).
    var canSubmit: Bool {
        guard let q = currentQuestion else { return false }
        switch q.kind {
        case .matching:        return matchingComplete
        case .fillInBlank:     return !fillInBlankText.trimmingCharacters(in: .whitespaces).isEmpty
        default:               return !selectedAnswerIds.isEmpty
        }
    }

    // MARK: - Load

    func loadIfNeeded() async {
        if !questions.isEmpty { return }
        await loadQuestions()
    }

    private func loadQuestions() async {
        phase = .loading
        error = nil
        do {
            let response = try await service.fetchQuestions(attemptId: attemptId)
            questions = response.questions
            currentIndex = 0
            phase = .questionDisplayed
        } catch let e as APIError {
            phase = .error
            error = e.localizedDescription
        } catch {
            phase = .error
            self.error = error.localizedDescription
        }
    }

    // MARK: - Selection (single / multi)

    func selectAnswer(_ answerId: Int) {
        guard phase == .questionDisplayed || phase == .answerSelected else { return }
        guard let q = currentQuestion else { return }

        switch q.kind {
        case .multipleAnswer:
            if let idx = selectedAnswerIds.firstIndex(of: answerId) {
                selectedAnswerIds.remove(at: idx)
            } else {
                selectedAnswerIds.append(answerId)
            }
        default:
            selectedAnswerIds = [answerId]
        }
        phase = selectedAnswerIds.isEmpty ? .questionDisplayed : .answerSelected
    }

    // MARK: - Selection (fill-in-blank)

    func onFillInBlankTextChanged(_ text: String) {
        fillInBlankText = text
        phase = text.trimmingCharacters(in: .whitespaces).isEmpty
            ? .questionDisplayed
            : .answerSelected
    }

    // MARK: - Selection (matching)
    //
    // Interaction model (mirrors Android):
    //   1. Tap an L item        → becomes selectedLeftId (highlighted)
    //   2. Tap an R item        → pair is formed, both highlight
    //   3. Tap a paired item    → unpair (allows re-matching)
    //   4. Tap a different L    → switches selection

    func selectMatchingAnswer(answerId: Int, matchSide: String) {
        guard phase == .questionDisplayed || phase == .answerSelected else { return }

        if matchSide == "L" {
            // If this L is already paired, unpair it and re-select it.
            if let pair = matchingPairs.first(where: { $0.leftId == answerId }) {
                matchingPairs.removeAll { $0.leftId == pair.leftId }
                selectedLeftId = answerId
                phase = matchingPairs.isEmpty ? .questionDisplayed : .answerSelected
            } else {
                selectedLeftId = answerId
            }
            return
        }

        // matchSide == "R"
        guard let leftId = selectedLeftId else { return }

        // If this R is already paired with something else, unpair it.
        if let existing = matchingPairs.first(where: { $0.rightId == answerId }) {
            matchingPairs.removeAll { $0.leftId == existing.leftId }
            selectedLeftId = leftId
            phase = matchingPairs.isEmpty ? .questionDisplayed : .answerSelected
            return
        }

        // Replace any existing pair using this L, then add the new pair.
        matchingPairs.removeAll { $0.leftId == leftId }
        matchingPairs.append((leftId: leftId, rightId: answerId))

        let allPaired = matchingComplete
        selectedLeftId = nil
        phase = allPaired ? .answerSelected : .questionDisplayed
    }

    func resetMatchingPairs() {
        matchingPairs.removeAll()
        selectedLeftId = nil
        phase = .questionDisplayed
    }

    // MARK: - Submit

    func submitAnswer() async {
        guard phase == .answerSelected, let q = currentQuestion else { return }

        let body: SubmitAnswerRequest = {
            switch q.kind {
            case .matching:
                return SubmitAnswerRequest(
                    questionId: q.questionId,
                    answerJson: AnswerJSONBuilder.matching(pairs: matchingPairs)
                )
            case .fillInBlank:
                return SubmitAnswerRequest(
                    questionId: q.questionId,
                    answerJson: AnswerJSONBuilder.fillInBlank(text: fillInBlankText)
                )
            case .multipleAnswer:
                return SubmitAnswerRequest(
                    questionId: q.questionId,
                    answerJson: AnswerJSONBuilder.multiple(answerIds: selectedAnswerIds)
                )
            case .singleAnswer, .trueFalse:
                return SubmitAnswerRequest(
                    questionId: q.questionId,
                    answerJson: AnswerJSONBuilder.single(answerId: selectedAnswerIds.first ?? 0)
                )
            }
        }()

        phase = .submitting
        error = nil
        do {
            let response = try await service.submitAnswer(attemptId: attemptId, request: body)
            answerResult = response
            questionsAnswered = response.questionsAnswered
            currentScore = response.currentScore
            phase = .answerRevealed
        } catch let e as APIError {
            phase = .error
            error = e.localizedDescription
        } catch {
            phase = .error
            self.error = error.localizedDescription
        }
    }

    // MARK: - Advance

    func nextQuestion() async {
        guard phase == .answerRevealed else { return }
        if isLastQuestion {
            await completeQuiz()
        } else {
            currentIndex += 1
            selectedAnswerIds.removeAll()
            fillInBlankText = ""
            matchingPairs.removeAll()
            selectedLeftId = nil
            answerResult = nil
            phase = .questionDisplayed
        }
    }

    // MARK: - Complete

    private func completeQuiz() async {
        phase = .completing
        error = nil
        do {
            let response = try await service.completeQuiz(attemptId: attemptId)
            completedResult = response   // view observes & pushes results
        } catch let e as APIError {
            phase = .error
            error = e.localizedDescription
        } catch {
            phase = .error
            self.error = error.localizedDescription
        }
    }

    // MARK: - Retry

    func retry() async {
        guard phase == .error else { return }
        if questions.isEmpty {
            await loadQuestions()
        } else if answerResult == nil {
            phase = .answerSelected
            error = nil
        } else {
            await completeQuiz()
        }
    }
}
