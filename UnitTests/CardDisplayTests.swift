
import Testing
import SwiftData
@testable import TopNote
import Foundation

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
    
    @Test func displayAnswerEmptyWithImage() {
        let card = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .none,
            content: "Question",
            answer: "",
            answerImageData: Data() // Mock image data
        )
        #expect(card.displayAnswer == "")
    }
    
    @Test func displayAnswerNilWithImage() {
        let card = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .none,
            content: "Question",
            answer: nil,
            answerImageData: Data() // Mock image data
        )
        #expect(card.displayAnswer == "")
    }
}
