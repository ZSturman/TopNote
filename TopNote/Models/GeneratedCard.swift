//
//  GeneratedCard.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/20/25.
//

import Foundation

// MARK: - Answer Extraction Helpers

/// Patterns that indicate an embedded answer in content
/// Supports: "Answer:", "A:", "→", "—", and newline separators
private let answerPatterns: [(pattern: String, isRegex: Bool)] = [
    ("\\bAnswer:\\s*", true),      // "Answer: ..."
    ("\\bA:\\s*", true),           // "A: ..."
    ("\\s*→\\s*", true),           // "→ ..."
    ("\\s*—\\s*", true),           // "— ..."
    ("\\s*\\|\\s*", true),         // "| ..."
]

/// Extracts answer from content if embedded, returns (cleanContent, extractedAnswer)
private func extractAnswerFromContent(_ content: String, existingAnswer: String?) -> (content: String, answer: String?) {
    // If there's already a valid answer, don't try to extract
    if let existing = existingAnswer, !existing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return (content, existing)
    }
    
    let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Try each pattern to find and extract answer
    for (pattern, isRegex) in answerPatterns {
        if isRegex {
            if let range = trimmedContent.range(of: pattern, options: .regularExpression, range: nil, locale: nil) {
                let questionPart = String(trimmedContent[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                let answerPart = String(trimmedContent[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Only extract if both parts are non-empty
                if !questionPart.isEmpty && !answerPart.isEmpty {
                    return (questionPart, answerPart)
                }
            }
        }
    }
    
    // Try newline separator (question on first line, answer on subsequent lines)
    let lines = trimmedContent.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    if lines.count >= 2 {
        // Check if second line looks like an answer (doesn't start with question word)
        let questionWords = ["what", "who", "when", "where", "why", "how", "which", "is", "are", "can", "do", "does"]
        let firstLine = lines[0].lowercased()
        let secondLine = lines[1].lowercased()
        
        // First line should be a question (ends with ? or starts with question word)
        let isQuestion = firstLine.hasSuffix("?") || questionWords.contains(where: { firstLine.hasPrefix($0) })
        // Second line should not be a question
        let isAnswer = !secondLine.hasSuffix("?") && !questionWords.contains(where: { secondLine.hasPrefix($0) })
        
        if isQuestion && isAnswer {
            let questionPart = lines[0]
            let answerPart = lines.dropFirst().joined(separator: " ")
            return (questionPart, answerPart)
        }
    }
    
    // No embedded answer found
    return (trimmedContent, nil)
}

/// Limits string to max length with ellipsis
private func limitLength(_ text: String, maxLength: Int) -> String {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.count > maxLength {
        return String(trimmed.prefix(maxLength - 3)) + "..."
    }
    return trimmed
}

#if canImport(FoundationModels)
import FoundationModels

/// A struct representing an AI-generated card that can be converted to a Card model.
/// Uses FoundationModels' @Generable protocol for on-device AI generation.
@available(iOS 26.0, macOS 26.0, *)
@Generable
struct GeneratedCard: Identifiable, Hashable {
    let id = UUID()
    
    /// The type of card: "note", "todo", or "flashcard"
    @Guide(description: "The type of card to generate. Must be exactly one of: 'note', 'todo', or 'flashcard'")
    var cardType: String
    
    /// The main content of the card. Keep concise for widget display.
    @Guide(description: "The main content text of the card. For flashcards, put ONLY the question here, NOT the answer. Keep it concise and under 150 characters for optimal widget display. Be clear and actionable.")
    var content: String
    
    /// The answer for flashcards only. Keep concise for widget display.
    @Guide(description: "The answer text for flashcard type cards only. This field is REQUIRED for flashcards - never leave empty. Keep under 100 characters for widget display. Should be nil or empty for notes and todos.")
    var answer: String?
    
    /// Converts the raw cardType string to the CardType enum
    var resolvedCardType: CardType {
        switch cardType.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) {
        case "flashcard":
            return .flashcard
        case "todo", "to-do":
            return .todo
        case "note":
            return .note
        default:
            return .note
        }
    }
    
    /// Extracts answer from content if it was embedded there (for flashcards)
    private var extracted: (content: String, answer: String?) {
        if resolvedCardType == .flashcard {
            return extractAnswerFromContent(content, existingAnswer: answer)
        }
        return (content, answer)
    }
    
    /// Validates and cleans the generated content, extracting any embedded answers for flashcards
    var cleanedContent: String {
        return limitLength(extracted.content, maxLength: 150)
    }
    
    /// Validates and cleans the generated answer, including any extracted from content
    var cleanedAnswer: String? {
        guard resolvedCardType == .flashcard else { return nil }
        
        guard let answerText = extracted.answer, !answerText.isEmpty else { return nil }
        let trimmed = answerText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        return limitLength(trimmed, maxLength: 100)
    }
    
    /// Check if this is a valid card
    var isValid: Bool {
        !cleanedContent.isEmpty
    }
}

/// Container for multiple generated cards
@available(iOS 26.0, macOS 26.0, *)
@Generable
struct GeneratedCardBatch {
    @Guide(description: "An array of generated cards. Generate the exact number of cards requested by the user. For flashcards, ALWAYS provide a separate answer field - never embed the answer in the content.")
    var cards: [GeneratedCard]
}

#endif

// MARK: - Fallback for older iOS versions

/// A simple struct for representing generated cards when FoundationModels is not available
struct GeneratedCardFallback: Identifiable, Hashable {
    let id = UUID()
    var cardType: String
    var content: String
    var answer: String?
    
    // Per-card options (can be edited individually)
    var priority: PriorityType = .none
    var isRecurring: Bool = true
    var repeatInterval: RepeatInterval = .every2Months
    var skipEnabled: Bool = false
    var skipPolicy: RepeatPolicy = .none
    var resetRepeatIntervalOnComplete: Bool = false
    var ratingEasyPolicy: RepeatPolicy = .mild
    var ratingMedPolicy: RepeatPolicy = .none
    var ratingHardPolicy: RepeatPolicy = .aggressive
    
    var resolvedCardType: CardType {
        switch cardType.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) {
        case "flashcard":
            return .flashcard
        case "todo", "to-do":
            return .todo
        case "note":
            return .note
        default:
            return .note
        }
    }
    
    /// Extracts answer from content if it was embedded there (for flashcards)
    private var extracted: (content: String, answer: String?) {
        if resolvedCardType == .flashcard {
            return extractAnswerFromContent(content, existingAnswer: answer)
        }
        return (content, answer)
    }
    
    var cleanedContent: String {
        return limitLength(extracted.content, maxLength: 150)
    }
    
    var cleanedAnswer: String? {
        guard resolvedCardType == .flashcard else { return nil }
        
        guard let answerText = extracted.answer, !answerText.isEmpty else { return nil }
        let trimmed = answerText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        return limitLength(trimmed, maxLength: 100)
    }
    
    var isValid: Bool {
        !cleanedContent.isEmpty
    }
}
