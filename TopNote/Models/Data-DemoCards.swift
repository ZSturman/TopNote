//
//  Data-DemoCards.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/29/25.
//

import Foundation

#if DEBUG
import SwiftData

/// Seed the SwiftData store with demo cards when running in the Simulator.
///
/// This creates a small set of cards directly in the model context, without
/// going through the JSON importer.
func seedDemoDataIfNeeded(into container: ModelContainer) {
    #if targetEnvironment(simulator)
    let context = ModelContext(container)
    
    // Only seed if there are already no cards.
    let descriptor = FetchDescriptor<Card>()
    if let existing = try? context.fetch(descriptor), existing.isEmpty == false {
        return
    }
    
    let now = Date()
    func hoursAgo(_ hours: Double) -> Date {
        now.addingTimeInterval(-hours * 3600)
    }
    
    // Folders
    let eventuallyFolder = Folder(name: "Eventually")
    let workFolder = Folder(name: "Work")
    let personalFolder = Folder(name: "Personal")
    let readingFolder = Folder(name: "Reading List")
    
    let allFolders = [eventuallyFolder, workFolder, personalFolder, readingFolder]
    allFolders.forEach { context.insert($0) }
    
    // Tags
    let tagSometime = CardTag(name: "sometime")
    let tagDeepWork = CardTag(name: "deep work")
    let tagErrand = CardTag(name: "errand")
    let tagReview = CardTag(name: "review")
    let tagIdea = CardTag(name: "idea")
    let tagQuickWin = CardTag(name: "quick win")
    let tagReading = CardTag(name: "reading")
    let tagQuote = CardTag(name: "quote")
    let tagAffirmation = CardTag(name: "affirmation")
    let tagEpiphany = CardTag(name: "epiphany")
    let tagAppIdea = CardTag(name: "app idea")
    let tagMeditation = CardTag(name: "meditation")
    let tagJoke = CardTag(name: "joke")

    let allTags = [
        tagSometime,
        tagDeepWork,
        tagErrand,
        tagReview,
        tagIdea,
        tagQuickWin,
        tagReading,
        tagQuote,
        tagAffirmation,
        tagEpiphany,
        tagAppIdea,
        tagMeditation,
        tagJoke
    ]
    allTags.forEach { context.insert($0) }
    
    // Helper to make a due or future queue date
    func dueSoon(hoursFromNow: Double) -> Date {
        now.addingTimeInterval(hoursFromNow * 3600)
    }
    
    // MARK: - To-do cards (10)
    let todo1 = Card(
        createdAt: hoursAgo(72),
        cardType: .todo,
        priorityTypeRaw: .high,
        content: "Inbox zero sweep",
        isRecurring: true,
        repeatInterval: 24,
        initialRepeatInterval: 24,
        nextTimeInQueue: dueSoon(hoursFromNow: -1),
        folder: eventuallyFolder,
        tags: [tagSometime, tagQuickWin],
        isArchived: true,
        isComplete: true,
        skipEnabled: false
    )
    
    let todo2 = Card(
        createdAt: hoursAgo(48),
        cardType: .todo,
        priorityTypeRaw: .med,
        content: "Plan weekly review",
        isRecurring: true,
        repeatInterval: 48,
        initialRepeatInterval: 48,
        nextTimeInQueue: dueSoon(hoursFromNow: 6),
        folder: workFolder,
        tags: [tagDeepWork, tagReview],
        skipPolicy: .mild,
        ratingEasyPolicy: .aggressive,
        ratingMedPolicy: .none,
        ratingHardPolicy: .mild
    )
    
    let todo3 = Card(
        createdAt: hoursAgo(36),
        cardType: .todo,
        priorityTypeRaw: .low,
        content: "Refactor old project",
        isRecurring: true,
        repeatInterval: 72,
        initialRepeatInterval: 72,
        nextTimeInQueue: dueSoon(hoursFromNow: 24),
        folder: personalFolder,
        tags: [tagIdea],
        skipPolicy: .aggressive,
        ratingEasyPolicy: .none,
        ratingMedPolicy: .mild,
        ratingHardPolicy: .aggressive
    )
    
    let todo4 = Card(
        createdAt: hoursAgo(96),
        cardType: .todo,
        priorityTypeRaw: .none,
        content: "Book dentist appointment",
        isRecurring: true,
        repeatInterval: 336,
        initialRepeatInterval: 168,
        nextTimeInQueue: dueSoon(hoursFromNow: -12),
        folder: readingFolder,
        tags: [tagErrand],
        skipEnabled: false
    )
    
    let todo5 = Card(
        createdAt: hoursAgo(12),
        cardType: .todo,
        priorityTypeRaw: .high,
        content: "Organize home office",
        isRecurring: true,
        repeatInterval: 240,
        initialRepeatInterval: 240,
        nextTimeInQueue: dueSoon(hoursFromNow: 72),
        folder: eventuallyFolder,
        tags: [tagQuickWin],
        isComplete: true
    )
    
    let todo6 = Card(
        createdAt: hoursAgo(120),
        cardType: .todo,
        priorityTypeRaw: .med,
        content: "Backup laptop",
        isRecurring: true,
        repeatInterval: 336,
        initialRepeatInterval: 336,
        nextTimeInQueue: dueSoon(hoursFromNow: 168),
        folder: workFolder,
        tags: [tagSometime, tagReview],
        isArchived: true,
        skipPolicy: .aggressive
    )
    
    let todo7 = Card(
        createdAt: hoursAgo(8),
        cardType: .todo,
        priorityTypeRaw: .low,
        content: "Call insurance",
        isRecurring: true,
        repeatInterval: 720,
        initialRepeatInterval: 720,
        nextTimeInQueue: dueSoon(hoursFromNow: 4),
        folder: personalFolder,
        tags: [tagErrand, tagReview]
    )
    
    let todo8 = Card(
        createdAt: hoursAgo(30),
        cardType: .todo,
        priorityTypeRaw: .none,
        content: "Clean up photo library",
        isRecurring: true,
        repeatInterval: 48,
        initialRepeatInterval: 48,
        nextTimeInQueue: dueSoon(hoursFromNow: -2),
        folder: readingFolder,
        tags: [tagQuickWin]
    )
    
    let todo9 = Card(
        createdAt: hoursAgo(4),
        cardType: .todo,
        priorityTypeRaw: .high,
        content: "Draft blog outline",
        isRecurring: true,
        repeatInterval: 72,
        initialRepeatInterval: 72,
        nextTimeInQueue: dueSoon(hoursFromNow: 12),
        folder: eventuallyFolder,
        tags: [tagDeepWork, tagIdea],
        skipPolicy: .aggressive
    )
    
    let todo10 = Card(
        createdAt: hoursAgo(20),
        cardType: .todo,
        priorityTypeRaw: .med,
        content: "Deep work block",
        isRecurring: true,
        repeatInterval: 168,
        initialRepeatInterval: 168,
        nextTimeInQueue: dueSoon(hoursFromNow: -5),
        folder: workFolder,
        tags: [tagDeepWork]
    )
    
    // MARK: - Flashcards (8)
    let flash1 = Card(
        createdAt: hoursAgo(60),
        cardType: .flashcard,
        priorityTypeRaw: .low,
        content: "What is spaced repetition?",
        isRecurring: true,
        repeatInterval: 240,
        initialRepeatInterval: 240,
        nextTimeInQueue: dueSoon(hoursFromNow: 48),
        folder: personalFolder,
        tags: [tagReading, tagReview],
        answer: "A learning technique that spaces reviews over time.",
        skipPolicy: .aggressive
    )
    
    let flash2 = Card(
        createdAt: hoursAgo(10),
        cardType: .flashcard,
        priorityTypeRaw: .none,
        content: "Define active recall.",
        isRecurring: true,
        repeatInterval: 24,
        initialRepeatInterval: 24,
        nextTimeInQueue: dueSoon(hoursFromNow: 1),
        folder: readingFolder,
        tags: [tagSometime, tagReview],
        answer: "Trying to remember information without looking at the answer."
    )
    
    let flash3 = Card(
        createdAt: hoursAgo(24),
        cardType: .flashcard,
        priorityTypeRaw: .high,
        content: "What is TopNote for?",
        isRecurring: true,
        repeatInterval: 48,
        initialRepeatInterval: 48,
        nextTimeInQueue: dueSoon(hoursFromNow: -3),
        folder: eventuallyFolder,
        tags: [tagSometime, tagIdea],
        answer: "Capturing, organizing, and revisiting your important notes and tasks.",
        ratingEasyPolicy: .aggressive
    )
    
    let flash4 = Card(
        createdAt: hoursAgo(5),
        cardType: .flashcard,
        priorityTypeRaw: .med,
        content: "Name one deep work tactic.",
        isRecurring: true,
        repeatInterval: 72,
        initialRepeatInterval: 72,
        nextTimeInQueue: dueSoon(hoursFromNow: 24),
        folder: workFolder,
        tags: [tagDeepWork],
        answer: "Time-block a 90-minute distraction-free focus session.",
        ratingMedPolicy: .mild
    )
    
    let flash5 = Card(
        createdAt: hoursAgo(18),
        cardType: .flashcard,
        priorityTypeRaw: .low,
        content: "What is a ‘policy’ in Top Note?",
        isRecurring: true,
        repeatInterval: 168,
        initialRepeatInterval: 168,
        nextTimeInQueue: dueSoon(hoursFromNow: -10),
        folder: personalFolder,
        tags: [tagReview],
        answer: "The rules for when cards reappear in the queue based on previous actions."
    )
    
    let flash6 = Card(
        createdAt: hoursAgo(40),
        cardType: .flashcard,
        priorityTypeRaw: .none,
        content: "Why batch shallow tasks?",
        isRecurring: true,
        repeatInterval: 336,
        initialRepeatInterval: 336,
        nextTimeInQueue: dueSoon(hoursFromNow: 120),
        folder: readingFolder,
        tags: [tagReading],
        answer: "To reduce overhead and save mental energy."
    )
    
    let flash7 = Card(
        createdAt: hoursAgo(14),
        cardType: .flashcard,
        priorityTypeRaw: .high,
        content: "What is Parkinson's Law?",
        isRecurring: true,
        repeatInterval: 720,
        initialRepeatInterval: 720,
        nextTimeInQueue: dueSoon(hoursFromNow: 300),
        folder: eventuallyFolder,
        tags: [tagIdea, tagReview],
        answer: "Work expands to fill the time available.",
        skipPolicy: .aggressive
    )
    
    let flash8 = Card(
        createdAt: hoursAgo(6),
        cardType: .flashcard,
        priorityTypeRaw: .med,
        content: "What is context switching?",
        isRecurring: true,
        repeatInterval: 24,
        initialRepeatInterval: 24,
        nextTimeInQueue: dueSoon(hoursFromNow: 2),
        folder: workFolder,
        tags: [tagQuickWin],
        answer: "Rapidly changing tasks, which reduces focus and efficiency."
    )
    
    // MARK: - Notes (12)
    let note1 = Card(
        createdAt: hoursAgo(72),
        cardType: .note,
        priorityTypeRaw: .low,
        content: "Start where you are. Use what you have. Do what you can.",
        isRecurring: true,
        repeatInterval: 48,
        initialRepeatInterval: 48,
        nextTimeInQueue: dueSoon(hoursFromNow: 12),
        folder: personalFolder,
        tags: [tagQuote],
        skipPolicy: .aggressive
    )

    let note2 = Card(
        createdAt: hoursAgo(30),
        cardType: .note,
        priorityTypeRaw: .none,
        content: "You’re doing better than you think.",
        isRecurring: true,
        repeatInterval: 72,
        initialRepeatInterval: 72,
        nextTimeInQueue: dueSoon(hoursFromNow: -4),
        folder: personalFolder,
        tags: [tagAffirmation]
    )

    let note3 = Card(
        createdAt: hoursAgo(12),
        cardType: .note,
        priorityTypeRaw: .high,
        content: "Most hard things aren’t actually hard; they’re just unfamiliar.",
        isRecurring: true,
        repeatInterval: 168,
        initialRepeatInterval: 168,
        nextTimeInQueue: dueSoon(hoursFromNow: 72),
        folder: workFolder,
        tags: [tagEpiphany]
    )

    let note4 = Card(
        createdAt: hoursAgo(48),
        cardType: .note,
        priorityTypeRaw: .med,
        content: "A journal that auto-highlights recurring themes in your entries.",
        isRecurring: true,
        repeatInterval: 240,
        initialRepeatInterval: 240,
        nextTimeInQueue: dueSoon(hoursFromNow: 168),
        folder: workFolder,
        tags: [tagAppIdea]
    )

    let note5 = Card(
        createdAt: hoursAgo(20),
        cardType: .note,
        priorityTypeRaw: .low,
        content: "Focus is a superpower—protect it like one.",
        isRecurring: true,
        repeatInterval: 336,
        initialRepeatInterval: 336,
        nextTimeInQueue: dueSoon(hoursFromNow: -2),
        folder: workFolder,
        tags: [tagQuote]
    )

    let note6 = Card(
        createdAt: hoursAgo(96),
        cardType: .note,
        priorityTypeRaw: .none,
        content: "A mentorship marketplace matching people by personality type and goals.",
        isRecurring: true,
        repeatInterval: 720,
        initialRepeatInterval: 720,
        nextTimeInQueue: dueSoon(hoursFromNow: 240),
        folder: workFolder,
        tags: [tagAppIdea]
    )

    let note7 = Card(
        createdAt: hoursAgo(8),
        cardType: .note,
        priorityTypeRaw: .high,
        content: "You don’t need more time; you need fewer conflicting priorities.",
        isRecurring: true,
        repeatInterval: 24,
        initialRepeatInterval: 24,
        nextTimeInQueue: dueSoon(hoursFromNow: 4),
        folder: workFolder,
        tags: [tagEpiphany]
    )

    let note8 = Card(
        createdAt: hoursAgo(16),
        cardType: .note,
        priorityTypeRaw: .med,
        content: "Notice the space between breaths—there’s clarity there.",
        isRecurring: true,
        repeatInterval: 48,
        initialRepeatInterval: 48,
        nextTimeInQueue: dueSoon(hoursFromNow: 1),
        folder: personalFolder,
        tags: [tagMeditation]
    )

    let note9 = Card(
        createdAt: hoursAgo(40),
        cardType: .note,
        priorityTypeRaw: .low,
        content: "Why did the programmer meditate? To avoid buffering.",
        isRecurring: true,
        repeatInterval: 72,
        initialRepeatInterval: 72,
        nextTimeInQueue: dueSoon(hoursFromNow: 24),
        folder: personalFolder,
        tags: [tagJoke]
    )

    let note10 = Card(
        createdAt: hoursAgo(60),
        cardType: .note,
        priorityTypeRaw: .none,
        content: "What gets measured gets improved.",
        isRecurring: true,
        repeatInterval: 168,
        initialRepeatInterval: 168,
        nextTimeInQueue: dueSoon(hoursFromNow: 96),
        folder: workFolder,
        tags: [tagQuote]
    )

    let note11 = Card(
        createdAt: hoursAgo(6),
        cardType: .note,
        priorityTypeRaw: .high,
        content: "Future you is proud of you already.",
        isRecurring: true,
        repeatInterval: 240,
        initialRepeatInterval: 240,
        nextTimeInQueue: dueSoon(hoursFromNow: -1),
        folder: personalFolder,
        tags: [tagAffirmation]
    )

    let note12 = Card(
        createdAt: hoursAgo(28),
        cardType: .note,
        priorityTypeRaw: .med,
        content: "Curiosity is a renewable resource. Use it daily.",
        isRecurring: true,
        repeatInterval: 336,
        initialRepeatInterval: 336,
        nextTimeInQueue: dueSoon(hoursFromNow: 72),
        folder: readingFolder,
        tags: [tagReading, tagEpiphany]
    )
    
    let allCards = [
        todo1, todo2, todo3, todo4, todo5,
        todo6, todo7, todo8, todo9, todo10,
        flash1, flash2, flash3, flash4,
        flash5, flash6, flash7, flash8,
        note1, note2, note3, note4, note5, note6,
        note7, note8, note9, note10, note11, note12
    ]
    
    allCards.forEach { context.insert($0) }
    
    do {
        try context.save()
        print("Seeded demo cards into simulator store.")
    } catch {
        print("Failed to seed demo cards: \(error)")
    }
    #endif
}
#endif
