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

// MARK: - Performance Tests

@Suite("Performance and Responsiveness Tests")
struct PerformanceTests {
    
    var modelContext: ModelContext
    var modelContainer: ModelContainer
    
    init() throws {
        let schema = Schema([Card.self, Folder.self, CardTag.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: config)
        modelContext = ModelContext(modelContainer)
    }
    
    // MARK: - JSON Decoding Performance (Cached Properties)
    
    @Test func cachedCompletesPerformance() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Performance test"
        )
        modelContext.insert(card)
        
        // Add some completion dates
        for i in 0..<100 {
            card.completes.append(Date().addingTimeInterval(TimeInterval(i * 3600)))
        }
        
        // First access should decode and cache
        let startFirst = CFAbsoluteTimeGetCurrent()
        let _ = card.completes
        let firstAccessTime = CFAbsoluteTimeGetCurrent() - startFirst
        
        // Second access should use cache
        let startSecond = CFAbsoluteTimeGetCurrent()
        let _ = card.completes
        let secondAccessTime = CFAbsoluteTimeGetCurrent() - startSecond
        
        // Cached access should be significantly faster
        #expect(secondAccessTime < firstAccessTime || secondAccessTime < 0.001)
    }
    
    @Test func cachedEnqueuesPerformance() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Performance test"
        )
        modelContext.insert(card)
        
        // Add many enqueue dates
        for i in 0..<100 {
            card.enqueues.append(Date().addingTimeInterval(TimeInterval(i * 3600)))
        }
        
        // Measure multiple accesses
        var accessTimes: [Double] = []
        for _ in 0..<10 {
            let start = CFAbsoluteTimeGetCurrent()
            let _ = card.enqueues.count
            accessTimes.append(CFAbsoluteTimeGetCurrent() - start)
        }
        
        // All cached accesses should be fast
        let averageTime = accessTimes.reduce(0, +) / Double(accessTimes.count)
        #expect(averageTime < 0.01) // Should be under 10ms average
    }
    
    @Test func cachedRemovalsPerformance() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Performance test"
        )
        modelContext.insert(card)
        
        // Add removal dates
        for i in 0..<50 {
            card.removals.append(Date().addingTimeInterval(TimeInterval(i * 3600)))
        }
        
        // Access multiple times and verify consistency
        let count1 = card.removals.count
        let count2 = card.removals.count
        let count3 = card.removals.count
        
        #expect(count1 == count2)
        #expect(count2 == count3)
        #expect(count1 == 50)
    }
    
    @Test func cachedSkipsPerformance() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Performance test"
        )
        modelContext.insert(card)
        
        // Add skip dates
        for i in 0..<100 {
            card.skips.append(Date().addingTimeInterval(TimeInterval(i * 3600)))
        }
        
        // Multiple rapid accesses should be fast
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<1000 {
            let _ = card.skips.last
        }
        let totalTime = CFAbsoluteTimeGetCurrent() - start
        
        // 1000 accesses should complete in under 1 second
        #expect(totalTime < 1.0)
    }
    
    // MARK: - Widget Throttling Tests
    
    @Test func widgetThrottlingPreventsRapidReloads() throws {
        // Reset the throttle state
        Card.throttledWidgetReload()
        
        // Immediately calling again should be throttled
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<100 {
            Card.throttledWidgetReload()
        }
        let totalTime = CFAbsoluteTimeGetCurrent() - start
        
        // 100 throttled calls should be nearly instant (< 100ms)
        // because most are skipped
        #expect(totalTime < 0.1)
    }
    
    // MARK: - Card Creation Performance
    
    @Test func bulkCardCreationPerformance() throws {
        let start = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<100 {
            let card = Card(
                createdAt: Date(),
                cardType: [CardType.todo, .flashcard, .note][i % 3],
                priorityTypeRaw: .none,
                content: "Card \(i)"
            )
            modelContext.insert(card)
        }
        
        let creationTime = CFAbsoluteTimeGetCurrent() - start
        
        // Creating 100 cards should take less than 1 second
        #expect(creationTime < 1.0)
    }
    
    @Test func bulkCardSavePerformance() throws {
        // Create cards
        for i in 0..<50 {
            let card = Card(
                createdAt: Date(),
                cardType: .todo,
                priorityTypeRaw: .none,
                content: "Card \(i)"
            )
            modelContext.insert(card)
        }
        
        // Measure save time
        let start = CFAbsoluteTimeGetCurrent()
        try modelContext.save()
        let saveTime = CFAbsoluteTimeGetCurrent() - start
        
        // Saving 50 cards should take less than 500ms
        #expect(saveTime < 0.5)
    }
    
    // MARK: - Content Update Performance (Simulating Typing)
    
    @Test func rapidContentUpdatesPerformance() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: ""
        )
        modelContext.insert(card)
        
        // Simulate typing by rapidly updating content
        let testString = "This is a test of rapid content updates to simulate typing behavior"
        
        let start = CFAbsoluteTimeGetCurrent()
        for (index, char) in testString.enumerated() {
            card.content = String(testString.prefix(index + 1))
        }
        let updateTime = CFAbsoluteTimeGetCurrent() - start
        
        // Rapid updates (without saving) should be very fast
        #expect(updateTime < 0.1)
        #expect(card.content == testString)
    }
    
    @Test func contentUpdateWithoutSaveDoesNotTriggerHeavyOperations() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: ""
        )
        modelContext.insert(card)
        
        // Add some data that would need JSON decoding
        for i in 0..<20 {
            card.enqueues.append(Date().addingTimeInterval(TimeInterval(i * 3600)))
            card.skips.append(Date().addingTimeInterval(TimeInterval(i * 3600)))
        }
        try modelContext.save()
        
        // Now simulate rapid typing
        let start = CFAbsoluteTimeGetCurrent()
        for i in 0..<100 {
            card.content = "Character \(i)"
            // Access computed properties during "typing"
            let _ = card.displayContent
            let _ = card.displayedDateForQueue
        }
        let updateTime = CFAbsoluteTimeGetCurrent() - start
        
        // Even with computed property access, updates should be fast
        #expect(updateTime < 0.5)
    }
    
    // MARK: - Filtering Performance
    
    @Test func cardFilteringPerformance() throws {
        // Create many cards with various states
        for i in 0..<200 {
            let card = Card(
                createdAt: Date().addingTimeInterval(TimeInterval(-i * 3600)),
                cardType: [CardType.todo, .flashcard, .note][i % 3],
                priorityTypeRaw: [PriorityType.none, .low, .med, .high][i % 4],
                content: "Card \(i)",
                isRecurring: i % 2 == 0,
                nextTimeInQueue: i % 3 == 0 ? Date().addingTimeInterval(-3600) : Date().addingTimeInterval(3600),
                isArchived: i % 5 == 0
            )
            modelContext.insert(card)
        }
        try modelContext.save()
        
        // Fetch all cards
        let descriptor = FetchDescriptor<Card>()
        let allCards = try modelContext.fetch(descriptor)
        
        // Measure filtering time
        let start = CFAbsoluteTimeGetCurrent()
        let queuedCards = allCards.filter { $0.isEnqueue(currentDate: Date()) && !$0.isArchived }
        let upcomingCards = allCards.filter { !$0.isEnqueue(currentDate: Date()) && !$0.isArchived }
        let archivedCards = allCards.filter { $0.isArchived }
        let filterTime = CFAbsoluteTimeGetCurrent() - start
        
        // Filtering 200 cards should be fast
        #expect(filterTime < 0.1)
        #expect(queuedCards.count + upcomingCards.count + archivedCards.count <= allCards.count)
    }
    
    // MARK: - Sorting Performance
    
    @Test func cardSortingPerformance() throws {
        // Create cards
        for i in 0..<100 {
            let card = Card(
                createdAt: Date().addingTimeInterval(TimeInterval(-i * 3600)),
                cardType: .todo,
                priorityTypeRaw: [PriorityType.none, .low, .med, .high][i % 4],
                content: "Card \(i)",
                nextTimeInQueue: Date().addingTimeInterval(TimeInterval((100 - i) * 3600))
            )
            modelContext.insert(card)
        }
        try modelContext.save()
        
        let descriptor = FetchDescriptor<Card>()
        let allCards = try modelContext.fetch(descriptor)
        
        // Measure sorting time
        let start = CFAbsoluteTimeGetCurrent()
        let sortedByDate = allCards.sorted { $0.nextTimeInQueue < $1.nextTimeInQueue }
        let sortedByCreated = allCards.sorted { $0.createdAt < $1.createdAt }
        let sortedByPriority = allCards.sorted { $0.priority.rawValue < $1.priority.rawValue }
        let sortTime = CFAbsoluteTimeGetCurrent() - start
        
        // Sorting 100 cards 3 ways should be fast
        #expect(sortTime < 0.1)
        #expect(sortedByDate.count == 100)
        #expect(sortedByCreated.count == 100)
        #expect(sortedByPriority.count == 100)
    }
    
    // MARK: - Tag Operations Performance
    
    @Test func tagOperationsPerformance() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Tagged card"
        )
        modelContext.insert(card)
        
        // Create many tags
        var tags: [CardTag] = []
        for i in 0..<50 {
            let tag = CardTag(name: "Tag\(i)")
            modelContext.insert(tag)
            tags.append(tag)
        }
        
        // Measure adding tags
        let addStart = CFAbsoluteTimeGetCurrent()
        for tag in tags {
            card.addTag(tag)
        }
        let addTime = CFAbsoluteTimeGetCurrent() - addStart
        
        #expect(addTime < 0.1)
        #expect(card.unwrappedTags.count == 50)
        
        // Measure removing tags
        let removeStart = CFAbsoluteTimeGetCurrent()
        for tag in tags {
            card.removeTag(tag)
        }
        let removeTime = CFAbsoluteTimeGetCurrent() - removeStart
        
        #expect(removeTime < 0.1)
        #expect(card.unwrappedTags.count == 0)
    }
    
    // MARK: - Rating History Performance
    
    @Test func ratingHistoryPerformance() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .none,
            content: "Q",
            isRecurring: true,
            answer: "A"
        )
        modelContext.insert(card)
        
        // Add many ratings
        let start = CFAbsoluteTimeGetCurrent()
        for i in 0..<100 {
            card.enqueue(at: Date())
            card.answerRevealed = true
            card.submitFlashcardRating([RatingType.easy, .good, .hard][i % 3], at: Date().addingTimeInterval(TimeInterval(i)))
        }
        let ratingTime = CFAbsoluteTimeGetCurrent() - start
        
        // Adding 100 ratings should be reasonably fast
        #expect(ratingTime < 2.0)
        #expect(card.rating.count == 100)
        
        // Accessing rating counts should be fast
        let countsStart = CFAbsoluteTimeGetCurrent()
        let _ = card.ratingCounts
        let _ = card.ratingEvents
        let countsTime = CFAbsoluteTimeGetCurrent() - countsStart
        
        #expect(countsTime < 0.1)
    }
}

// MARK: - Persistence Tests

@Suite("Data Persistence Tests")
struct PersistenceTests {
    
    var modelContext: ModelContext
    var modelContainer: ModelContainer
    
    init() throws {
        let schema = Schema([Card.self, Folder.self, CardTag.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: config)
        modelContext = ModelContext(modelContainer)
    }
    
    // MARK: - Save and Fetch Tests
    
    @Test func saveAndFetchCard() throws {
        let originalContent = "Test card content"
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .med,
            content: originalContent
        )
        modelContext.insert(card)
        try modelContext.save()
        
        // Fetch and verify
        let descriptor = FetchDescriptor<Card>()
        let fetchedCards = try modelContext.fetch(descriptor)
        
        #expect(fetchedCards.count >= 1)
        #expect(fetchedCards.contains { $0.content == originalContent })
    }
    
    @Test func saveAndFetchWithRelationships() throws {
        let folder = Folder(name: "Test Folder")
        modelContext.insert(folder)
        
        let tag = CardTag(name: "important")
        modelContext.insert(tag)
        
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .high,
            content: "Card with relationships",
            folder: folder,
            tags: [tag]
        )
        modelContext.insert(card)
        try modelContext.save()
        
        // Fetch and verify relationships
        let descriptor = FetchDescriptor<Card>()
        let fetchedCards = try modelContext.fetch(descriptor)
        let fetchedCard = fetchedCards.first { $0.content == "Card with relationships" }
        
        #expect(fetchedCard != nil)
        #expect(fetchedCard?.folder?.name == "Test Folder")
        #expect(fetchedCard?.unwrappedTags.count == 1)
    }
    
    @Test func saveComplexCardState() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .high,
            content: "Complex card",
            isRecurring: true,
            skipCount: 5,
            seenCount: 10,
            repeatInterval: 168,
            answer: "Answer text",
            skipPolicy: .mild,
            ratingEasyPolicy: .aggressive
        )
        modelContext.insert(card)
        
        // Add history data
        card.enqueues.append(Date())
        card.skips.append(Date())
        card.completes.append(Date())
        card.rating.append([.easy: Date()])
        
        try modelContext.save()
        
        // Fetch and verify all data persisted
        let descriptor = FetchDescriptor<Card>()
        let fetchedCards = try modelContext.fetch(descriptor)
        let fetchedCard = fetchedCards.first { $0.content == "Complex card" }
        
        #expect(fetchedCard != nil)
        #expect(fetchedCard?.skipCount == 5)
        #expect(fetchedCard?.seenCount == 10)
        #expect(fetchedCard?.enqueues.count == 1)
        #expect(fetchedCard?.skips.count == 1)
        #expect(fetchedCard?.completes.count == 1)
        #expect(fetchedCard?.rating.count == 1)
    }
    
    // MARK: - Delete Tests
    
    @Test func deleteCard() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "To be deleted"
        )
        modelContext.insert(card)
        try modelContext.save()
        
        // Delete
        modelContext.delete(card)
        try modelContext.save()
        
        // Verify deleted
        let descriptor = FetchDescriptor<Card>()
        let fetchedCards = try modelContext.fetch(descriptor)
        
        #expect(!fetchedCards.contains { $0.content == "To be deleted" })
    }
    
    @Test func deleteCardPreservesTags() throws {
        let tag = CardTag(name: "preserved")
        modelContext.insert(tag)
        
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Card to delete",
            tags: [tag]
        )
        modelContext.insert(card)
        try modelContext.save()
        
        // Delete card
        modelContext.delete(card)
        try modelContext.save()
        
        // Tag should still exist
        let tagDescriptor = FetchDescriptor<CardTag>()
        let fetchedTags = try modelContext.fetch(tagDescriptor)
        
        #expect(fetchedTags.contains { $0.name == "preserved" })
    }
    
    // MARK: - Bulk Operations Tests
    
    @Test func bulkInsertAndDelete() throws {
        // Bulk insert
        var cardIds: [UUID] = []
        for i in 0..<50 {
            let card = Card(
                createdAt: Date(),
                cardType: .todo,
                priorityTypeRaw: .none,
                content: "Bulk card \(i)"
            )
            modelContext.insert(card)
            cardIds.append(card.id)
        }
        try modelContext.save()
        
        // Verify all inserted
        var descriptor = FetchDescriptor<Card>()
        var fetchedCards = try modelContext.fetch(descriptor)
        let insertedCount = fetchedCards.filter { $0.content.starts(with: "Bulk card") }.count
        #expect(insertedCount == 50)
        
        // Bulk delete
        for card in fetchedCards where card.content.starts(with: "Bulk card") {
            modelContext.delete(card)
        }
        try modelContext.save()
        
        // Verify all deleted
        descriptor = FetchDescriptor<Card>()
        fetchedCards = try modelContext.fetch(descriptor)
        let remainingCount = fetchedCards.filter { $0.content.starts(with: "Bulk card") }.count
        #expect(remainingCount == 0)
    }
}

// MARK: - Export Tests

@Suite("Export and Import Tests")
struct ExportTests {
    
    var modelContext: ModelContext
    var modelContainer: ModelContainer
    
    init() throws {
        let schema = Schema([Card.self, Folder.self, CardTag.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: config)
        modelContext = ModelContext(modelContainer)
    }
    
    @Test func exportCardToJSON() throws {
        let folder = Folder(name: "Export Folder")
        modelContext.insert(folder)
        
        let tag = CardTag(name: "exported")
        modelContext.insert(tag)
        
        let card = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .high,
            content: "Export test question",
            isRecurring: true,
            folder: folder,
            tags: [tag],
            answer: "Export test answer"
        )
        modelContext.insert(card)
        
        // Add some history
        card.enqueues.append(Date())
        card.rating.append([.easy: Date()])
        
        try modelContext.save()
        
        // Export
        let exportData = try Card.exportCardsToJSON([card])
        
        #expect(exportData.count > 0)
        
        // Verify JSON is valid
        let decoded = try JSONDecoder().decode([CardExport].self, from: exportData)
        #expect(decoded.count == 1)
        #expect(decoded[0].content == "Export test question")
        #expect(decoded[0].folder == "Export Folder")
        #expect(decoded[0].tags.contains("exported"))
    }
    
    @Test func exportMultipleCardsToCSV() throws {
        for i in 0..<5 {
            let card = Card(
                createdAt: Date(),
                cardType: [CardType.todo, .flashcard, .note][i % 3],
                priorityTypeRaw: .none,
                content: "CSV Card \(i)",
                answer: i % 3 == 1 ? "Answer \(i)" : nil
            )
            modelContext.insert(card)
        }
        try modelContext.save()
        
        let descriptor = FetchDescriptor<Card>()
        let cards = try modelContext.fetch(descriptor).filter { $0.content.starts(with: "CSV Card") }
        
        let csvString = try Card.exportCardsToCSV(cards)
        
        #expect(csvString.contains("cardType"))
        #expect(csvString.contains("content"))
        #expect(csvString.contains("CSV Card"))
    }
    
    @Test func exportDTOContainsAllFields() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .high,
            content: "DTO test",
            isRecurring: true,
            skipCount: 3,
            seenCount: 5,
            repeatInterval: 168,
            initialRepeatInterval: 240,
            isArchived: false,
            skipPolicy: .mild,
            ratingEasyPolicy: .aggressive,
            isComplete: false,
            resetRepeatIntervalOnComplete: true,
            skipEnabled: true
        )
        modelContext.insert(card)
        
        let dto = card.exportDTO
        
        #expect(dto.content == "DTO test")
        #expect(dto.cardType == "To-do")
        #expect(dto.priority == PriorityType.high.rawValue)
        #expect(dto.isRecurring == true)
        #expect(dto.skipCount == 3)
        #expect(dto.seenCount == 5)
        #expect(dto.repeatInterval == 168)
        #expect(dto.initialRepeatInterval == 240)
    }
}

// MARK: - Memory and Scaling Tests

@Suite("Memory and Scaling Tests")
struct ScalingTests {
    
    var modelContext: ModelContext
    var modelContainer: ModelContainer
    
    init() throws {
        let schema = Schema([Card.self, Folder.self, CardTag.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: config)
        modelContext = ModelContext(modelContainer)
    }
    
    @Test func handleLargeNumberOfCards() throws {
        // Create 500 cards
        for i in 0..<500 {
            let card = Card(
                createdAt: Date().addingTimeInterval(TimeInterval(-i * 60)),
                cardType: [CardType.todo, .flashcard, .note][i % 3],
                priorityTypeRaw: [PriorityType.none, .low, .med, .high][i % 4],
                content: "Large scale card \(i)"
            )
            modelContext.insert(card)
        }
        try modelContext.save()
        
        // Fetch all
        let descriptor = FetchDescriptor<Card>()
        let allCards = try modelContext.fetch(descriptor)
        
        #expect(allCards.count >= 500)
        
        // Filter operations should still be fast
        let start = CFAbsoluteTimeGetCurrent()
        let filtered = allCards.filter { $0.content.contains("scale") }
        let filterTime = CFAbsoluteTimeGetCurrent() - start
        
        #expect(filterTime < 0.5)
        #expect(filtered.count == 500)
    }
    
    @Test func handleCardWithLongContent() throws {
        // Create a card with very long content
        let longContent = String(repeating: "This is a very long content string. ", count: 1000)
        
        let card = Card(
            createdAt: Date(),
            cardType: .note,
            priorityTypeRaw: .none,
            content: longContent
        )
        modelContext.insert(card)
        try modelContext.save()
        
        // Access should be fast
        let start = CFAbsoluteTimeGetCurrent()
        let _ = card.displayContent
        let accessTime = CFAbsoluteTimeGetCurrent() - start
        
        #expect(accessTime < 0.1)
        #expect(card.content.count > 30000)
    }
    
    @Test func handleCardWithLargeHistory() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .none,
            content: "History test",
            isRecurring: true,
            answer: "Answer"
        )
        modelContext.insert(card)
        
        // Add large history
        for i in 0..<500 {
            card.enqueues.append(Date().addingTimeInterval(TimeInterval(i)))
            card.skips.append(Date().addingTimeInterval(TimeInterval(i)))
        }
        try modelContext.save()
        
        // Access should still be reasonably fast due to caching
        let start = CFAbsoluteTimeGetCurrent()
        let _ = card.enqueues.count
        let _ = card.skips.count
        let accessTime = CFAbsoluteTimeGetCurrent() - start
        
        #expect(accessTime < 0.5)
        #expect(card.enqueues.count == 500)
        #expect(card.skips.count == 500)
    }
    
    @Test func handleManyTags() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            content: "Many tags card"
        )
        modelContext.insert(card)
        
        // Add many tags
        for i in 0..<100 {
            let tag = CardTag(name: "Tag\(i)")
            modelContext.insert(tag)
            card.addTag(tag)
        }
        try modelContext.save()
        
        #expect(card.unwrappedTags.count == 100)
        
        // Tag access should be fast
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<100 {
            let _ = card.unwrappedTags.map { $0.name }
        }
        let accessTime = CFAbsoluteTimeGetCurrent() - start
        
        #expect(accessTime < 0.5)
    }
    
    @Test func handleManyFolders() throws {
        // Create many folders
        var folders: [Folder] = []
        for i in 0..<100 {
            let folder = Folder(name: "Folder \(i)")
            modelContext.insert(folder)
            folders.append(folder)
        }
        
        // Create cards in each folder
        for (index, folder) in folders.enumerated() {
            let card = Card(
                createdAt: Date(),
                cardType: .todo,
                priorityTypeRaw: .none,
                content: "Card in folder \(index)",
                folder: folder
            )
            modelContext.insert(card)
        }
        try modelContext.save()
        
        // Fetch by folder should be fast
        let descriptor = FetchDescriptor<Card>()
        let allCards = try modelContext.fetch(descriptor)
        
        let start = CFAbsoluteTimeGetCurrent()
        let cardsInFirstFolder = allCards.filter { $0.folder?.name == "Folder 0" }
        let filterTime = CFAbsoluteTimeGetCurrent() - start
        
        #expect(filterTime < 0.1)
        #expect(cardsInFirstFolder.count >= 1)
    }
}
