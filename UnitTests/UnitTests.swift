//
//  UnitTests.swift
//  UnitTests
//
//  Created by Zachary Sturman on 11/15/25.
//

import Testing
import SwiftData
@testable import TopNote
import Foundation

// MARK: - Card Timing Tests

@Suite("Card Timing and Scheduling Tests")
struct CardTimingTests {
    
    var modelContext: ModelContext
    var modelContainer: ModelContainer
    
    init() throws {
        let schema = Schema([Card.self, Folder.self, CardTag.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: config)
        modelContext = ModelContext(modelContainer)
    }
    
    // MARK: - Repeat Interval Tests
    
    @Test func cardDefaultRepeatInterval() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Test card"
        )
        
        #expect(card.repeatInterval == 240)
        #expect(card.initialRepeatInterval == 240)
    }
    
    @Test func repeatIntervalEnumConversion() throws {
        #expect(RepeatInterval.daily.hours == 24)
        #expect(RepeatInterval.weekly.hours == 168)
        #expect(RepeatInterval.monthly.hours == 720)
        #expect(RepeatInterval.yearly.hours == 8760)
    }
    
    @Test func repeatIntervalInitFromHours() throws {
        #expect(RepeatInterval(hours: 24) == .daily)
        #expect(RepeatInterval(hours: 720) == .monthly)
        #expect(RepeatInterval(hours: 8760) == .yearly)
    }
    
    // MARK: - Skip Policy Tests
    
    @Test func skipPolicyMultipliers() throws {
        #expect(RepeatPolicy.aggressive.skipMultiplier == 0.5)
        #expect(RepeatPolicy.mild.skipMultiplier == 0.75)
        #expect(RepeatPolicy.none.skipMultiplier == 1.0)
    }
    
    @Test func skipWithAggressivePolicy() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Test",
            repeatInterval: 240,
            skipPolicy: .aggressive
        )
        modelContext.insert(card)
        
        let currentDate = Date()
        card.skip(at: currentDate)
        
        #expect(card.repeatInterval == 120)
        #expect(card.skipCount == 1)
        #expect(card.skips.count == 1)
    }
    
    @Test func skipWithMildPolicy() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .none,
            content: "Question",
            repeatInterval: 240, answer: "Answer",
            skipPolicy: .mild
        )
        modelContext.insert(card)
        
        let currentDate = Date()
        card.skip(at: currentDate)
        
        #expect(card.repeatInterval == 180)
        #expect(card.skipCount == 1)
    }
    
    @Test func multipleSkipsCompound() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Test",
            repeatInterval: 480,
            skipPolicy: .aggressive
        )
        modelContext.insert(card)
        
        var currentDate = Date()
        
        card.skip(at: currentDate)
        #expect(card.repeatInterval == 240)
        
        currentDate = currentDate.addingTimeInterval(3600)
        
        card.skip(at: currentDate)
        #expect(card.repeatInterval == 120)
        
        #expect(card.skipCount == 2)
        #expect(card.skips.count == 2)
    }
    
    @Test func skipNoteSpecialRule() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .note,
            priorityTypeRaw: .none,
            content: "Note",
            repeatInterval: 240,
            skipPolicy: .aggressive
        )
        modelContext.insert(card)
        
        let currentDate = Date()
        card.skip(at: currentDate)
        
        // Note special rule: Notes always get MORE time when skipped (reciprocal logic)
        // skipMultiplier is 0.5, so we use 1/0.5 = 2.0, then max(2.0, 2.0) = 2.0
        // 240 * 2.0 = 480
        #expect(card.repeatInterval == 480)
    }
    
    // MARK: - Rating Policy Tests
    
    @Test func ratingEasyPolicyAggressive() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .none,
            content: "Question",
            isRecurring: true, repeatInterval: 240, answer: "Answer",
            ratingEasyPolicy: .aggressive
        )
        modelContext.insert(card)
        card.enqueue(at: Date())
        card.answerRevealed = true
        
        let currentDate = Date()
        card.submitFlashcardRating(.easy, at: currentDate)
        
        #expect(card.repeatInterval == 360)
        #expect(card.rating.count == 1)
    }
    
    @Test func ratingHardPolicyAggressive() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .none,
            content: "Question",
            isRecurring: true, repeatInterval: 240, answer: "Answer",
            ratingHardPolicy: .aggressive
        )
        modelContext.insert(card)
        card.enqueue(at: Date())
        card.answerRevealed = true
        
        let currentDate = Date()
        card.submitFlashcardRating(.hard, at: currentDate)
        
        #expect(card.repeatInterval == 120)
    }
    
    @Test func ratingPolicyNone() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .none,
            content: "Question",
            isRecurring: true, repeatInterval: 240, answer: "Answer",
            ratingEasyPolicy: .none,
            ratingMedPolicy: .none,
            ratingHardPolicy: .none
        )
        modelContext.insert(card)
        card.enqueue(at: Date())
        card.answerRevealed = true
        
        let currentDate = Date()
        
        card.submitFlashcardRating(.easy, at: currentDate)
        #expect(card.repeatInterval == 240)
        
        card.submitFlashcardRating(.good, at: currentDate.addingTimeInterval(3600))
        #expect(card.repeatInterval == 240)
        
        card.submitFlashcardRating(.hard, at: currentDate.addingTimeInterval(7200))
        #expect(card.repeatInterval == 240)
    }
    
    // MARK: - Interval Clamping Tests
    
    @Test func intervalClampingMinimum() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .none,
            content: "Question",
            isRecurring: true, repeatInterval: 24, answer: "Answer",
            ratingHardPolicy: .aggressive
        )
        modelContext.insert(card)
        card.enqueue(at: Date())
        card.answerRevealed = true
        
        card.submitFlashcardRating(.hard, at: Date())
        
        #expect(card.repeatInterval == 24)
    }
    
    @Test func intervalClampingMaximum() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .none,
            content: "Question",
            isRecurring: true, repeatInterval: 8000, answer: "Answer",
            ratingEasyPolicy: .aggressive
        )
        modelContext.insert(card)
        card.enqueue(at: Date())
        card.answerRevealed = true
        
        card.submitFlashcardRating(.easy, at: Date())
        
        #expect(card.repeatInterval == 8760)
    }
    
    // MARK: - Complete and Reset Tests
    
    @Test func completeResetsInterval() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Test",
            isRecurring: true,
            repeatInterval: 480,
            initialRepeatInterval: 240,
            resetRepeatIntervalOnComplete: true
        )
        modelContext.insert(card)
        
        card.markAsComplete(at: Date())
        
        #expect(card.repeatInterval == 240)
        #expect(card.completes.count == 1)
    }
    
    @Test func completeDoesNotResetWhenDisabled() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Test",
            isRecurring: true,
            repeatInterval: 480,
            initialRepeatInterval: 240,
            resetRepeatIntervalOnComplete: false
        )
        modelContext.insert(card)
        
        card.markAsComplete(at: Date())
        
        #expect(card.repeatInterval == 480)
    }
    
    // MARK: - Complex Scenarios
    
    @Test func monthlyCardWithAggressiveSkip() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .high,
            content: "Monthly review",
            isRecurring: true,
            repeatInterval: RepeatInterval.monthly.hours!,
            initialRepeatInterval: RepeatInterval.monthly.hours!,
            skipPolicy: .aggressive
        )
        modelContext.insert(card)
        
        let currentDate = Date()
        card.skip(at: currentDate)
        
        #expect(card.repeatInterval == 360)
    }
    
    @Test func flashcardProgressionEasyPath() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .none,
            content: "What is 2+2?",
            isRecurring: true, repeatInterval: RepeatInterval.daily.hours!, initialRepeatInterval: RepeatInterval.daily.hours!, answer: "4",
            ratingEasyPolicy: .mild
        )
        modelContext.insert(card)
        card.enqueue(at: Date())
        
        var currentDate = Date()
        
        card.answerRevealed = true
        card.submitFlashcardRating(.easy, at: currentDate)
        #expect(card.repeatInterval == 30)
        
        currentDate = currentDate.addingTimeInterval(TimeInterval(30 * 3600))
        card.enqueue(at: currentDate)
        card.answerRevealed = true
        card.submitFlashcardRating(.easy, at: currentDate)
        #expect(card.repeatInterval == 37)
        
        currentDate = currentDate.addingTimeInterval(TimeInterval(37 * 3600))
        card.enqueue(at: currentDate)
        card.answerRevealed = true
        card.submitFlashcardRating(.easy, at: currentDate)
        #expect(card.repeatInterval == 46)
    }
}

// MARK: - Card State Tests

@Suite("Card State and Lifecycle Tests")
struct CardStateTests {
    
    var modelContext: ModelContext
    var modelContainer: ModelContainer
    
    init() throws {
        let schema = Schema([Card.self, Folder.self, CardTag.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: config)
        modelContext = ModelContext(modelContainer)
    }
    
    // MARK: - Enqueue Tests
    
    @Test func cardEnqueue() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Test",
            nextTimeInQueue: Date().addingTimeInterval(3600)
        )
        modelContext.insert(card)
        
        let currentDate = Date()
        card.enqueue(at: currentDate)
        
        #expect(card.isEnqueue(currentDate: currentDate))
        #expect(card.seenCount == 1)
        #expect(card.enqueues.count == 1)
        #expect(!card.isArchived)
        #expect(!card.isComplete)
    }
    

    
    @Test func isEnqueueWhenDue() throws {
        let currentDate = Date()
        let pastDate = currentDate.addingTimeInterval(-3600)
        
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Test",
            nextTimeInQueue: pastDate
        )
        modelContext.insert(card)
        
        #expect(card.isEnqueue(currentDate: currentDate))
    }
    
    @Test func isNotEnqueueWhenNotDue() throws {
        let currentDate = Date()
        let futureDate = currentDate.addingTimeInterval(3600)
        
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Test",
            nextTimeInQueue: futureDate
        )
        modelContext.insert(card)
        
        #expect(!card.isEnqueue(currentDate: currentDate))
    }
    
    @Test func isNotEnqueueWhenArchived() throws {
        let currentDate = Date()
        
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Test",
            nextTimeInQueue: currentDate, isArchived: true
        )
        modelContext.insert(card)
        
        #expect(!card.isEnqueue(currentDate: currentDate))
    }
    
    // MARK: - Archive Tests
    
    @Test func archiveCard() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Test",
            nextTimeInQueue: Date()
        )
        modelContext.insert(card)
        
        let currentDate = Date()
        card.enqueue(at: currentDate)
        card.archive(at: currentDate)
        
        #expect(card.isArchived)
        #expect(card.removals.count == 1)
        #expect(card.nextTimeInQueue == .distantFuture)
        #expect(!card.answerRevealed)
    }
    
    @Test func unarchiveCard() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Test",
            nextTimeInQueue: .distantFuture, isArchived: true
        )
        modelContext.insert(card)
        
        let currentDate = Date()
        card.unarchive(at: currentDate)
        
        #expect(!card.isArchived)
        #expect(!card.isComplete)
        #expect(card.nextTimeInQueue != .distantFuture)
        #expect(!card.answerRevealed)
    }
    
    // MARK: - Complete Tests
    
    @Test func markTodoAsComplete() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Complete this task",
            isRecurring: true
        )
        modelContext.insert(card)
        
        let currentDate = Date()
        card.markAsComplete(at: currentDate)
        
        #expect(card.completes.count == 1)
        #expect(!card.answerRevealed)
    }
    
    @Test func markNonRecurringTodoAsComplete() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "One-time task",
            isRecurring: false
        )
        modelContext.insert(card)
        
        let currentDate = Date()
        card.markAsComplete(at: currentDate)
        
        #expect(card.isArchived)
        #expect(card.isComplete)
        #expect(card.completes.count == 1)
    }
    
    @Test func markRecurringTodoAsComplete() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Recurring task",
            isRecurring: true,
            repeatInterval: 168
        )
        modelContext.insert(card)
        
        let currentDate = Date()
        card.markAsComplete(at: currentDate)
        
        #expect(!card.isArchived)
        #expect(!card.isComplete)
    }
    
    @Test func markAsNotComplete() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Task",
            isRecurring: false,
            isComplete: true
        )
        modelContext.insert(card)
        
        card.completes.append(Date())
        
        let currentDate = Date()
        card.markAsNotComplete(at: currentDate)
        
        #expect(!card.isComplete)
        #expect(card.completes.count == 0)
        #expect(!card.answerRevealed)
    }
    
    // MARK: - Flashcard Tests
    
    @Test func flashcardRatingRecorded() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .none,
            content: "Question",
            isRecurring: true, answer: "Answer"
        )
        modelContext.insert(card)
        card.enqueue(at: Date())
        card.answerRevealed = true
        
        card.submitFlashcardRating(.easy, at: Date())
        
        #expect(card.rating.count == 1)
        #expect(!card.answerRevealed)
    }
    
    @Test func nonRecurringFlashcardArchivesAfterRating() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .none,
            content: "Question",
            isRecurring: false, answer: "Answer"
        )
        modelContext.insert(card)
        card.enqueue(at: Date())
        card.answerRevealed = true
        
        card.submitFlashcardRating(.good, at: Date())
        
        #expect(card.isArchived)
    }
    
    @Test func recurringFlashcardDoesNotArchiveAfterRating() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .none,
            content: "Question",
            isRecurring: true, answer: "Answer"
        )
        modelContext.insert(card)
        card.enqueue(at: Date())
        card.answerRevealed = true
        
        card.submitFlashcardRating(.good, at: Date())
        
        #expect(!card.isArchived)
    }
    
    @Test func showAnswer() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .none,
            content: "Question",
            answer: "Answer"
        )
        modelContext.insert(card)
        
        #expect(!card.answerRevealed)
        
        card.showAnswer(at: Date())
        
        #expect(card.answerRevealed)
    }
    
    // MARK: - Skip Tests
    
    @Test func skipIncrementsCounter() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Task"
        )
        modelContext.insert(card)
        
        #expect(card.skipCount == 0)
        
        card.skip(at: Date())
        #expect(card.skipCount == 1)
        
        card.skip(at: Date())
        #expect(card.skipCount == 2)
    }
    
    @Test func skipRecordsDate() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .none,
            content: "Q",
            answer: "A"
        )
        modelContext.insert(card)
        
        let currentDate = Date()
        card.skip(at: currentDate)
        
        #expect(card.skips.count == 1)
    }
    
    @Test func skipHidesAnswer() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .none,
            content: "Q",
            answer: "A"
        )
        modelContext.insert(card)
        
        card.answerRevealed = true
        card.skip(at: Date())
        
        #expect(!card.answerRevealed)
    }
    
    // MARK: - Tag Management Tests
    
    @Test func addTag() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Task"
        )
        modelContext.insert(card)
        
        let tag = CardTag(name: "important")
        modelContext.insert(tag)
        
        #expect(card.unwrappedTags.count == 0)
        
        card.addTag(tag)
        
        #expect(card.unwrappedTags.count == 1)
        #expect(card.unwrappedTags.contains { $0.id == tag.id })
    }
    
    @Test func addDuplicateTag() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Task"
        )
        modelContext.insert(card)
        
        let tag = CardTag(name: "urgent")
        modelContext.insert(tag)
        
        card.addTag(tag)
        card.addTag(tag)
        
        #expect(card.unwrappedTags.count == 1)
    }
    
    @Test func removeTag() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Task"
        )
        modelContext.insert(card)
        
        let tag = CardTag(name: "test")
        modelContext.insert(tag)
        
        card.addTag(tag)
        #expect(card.unwrappedTags.count == 1)
        
        card.removeTag(tag)
        #expect(card.unwrappedTags.count == 0)
    }
    
    // MARK: - Recurring vs Non-Recurring
    
    @Test func recurringCardNeverCompletes() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Daily task",
            isRecurring: true
        )
        modelContext.insert(card)
        
        for _ in 0..<5 {
            card.markAsComplete(at: Date())
            #expect(!card.isComplete)
            #expect(!card.isArchived)
        }
        
        #expect(card.completes.count == 5)
    }
    
    @Test func nonRecurringCardCompletesAndArchives() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "One-time task",
            isRecurring: false
        )
        modelContext.insert(card)
        
        card.markAsComplete(at: Date())
        
        #expect(card.isComplete)
        #expect(card.isArchived)
    }
}
