
@testable import TopNote
import SwiftData
import Foundation
import Testing

// MARK: - Card Display Logic Tests

@Suite("Card Display Logic Tests")
struct CardDisplayTests {
    
    @Test func displayAnswerWithText() {
        let card = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .none,
            content: "Question",
            answer: "The Answer"
        )
        #expect(card.displayAnswer == "The Answer")
    }
    
    @Test func displayAnswerEmptyWithNoImage() {
        let card = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .none,
            content: "Question",
            answer: ""
        )
        #expect(card.displayAnswer == "Answer here...")
    }
    
    @Test func displayAnswerNilWithNoImage() {
        let card = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .none,
            content: "Question",
            answer: nil
        )
        #expect(card.displayAnswer == "Answer here...")
    }
}
