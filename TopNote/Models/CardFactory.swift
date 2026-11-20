//
//  CardFactory.swift
//  TopNote
//
//  One place for how each kind of card starts out, shared by Capture, Siri and Reminders import.
//

import Foundation
import SwiftData

enum CardFactory {
    /// How long until a note first comes back. Notes resurface; they are never due.
    enum NoteReturn: String, CaseIterable, Identifiable {
        case week = "1 week"
        case month = "1 month"
        case threeMonths = "3 months"
        case sixMonths = "6 months"
        case once = "Once"

        var id: String { rawValue }

        var hours: Int {
            switch self {
            case .week: 168
            case .month: 720
            case .threeMonths: 2160
            case .sixMonths: 4320
            case .once: 720
            }
        }

        var isRecurring: Bool { self != .once }

        var explanation: String {
            switch self {
            case .once: "Comes back once in a month, then archives itself."
            default: "Comes back in \(rawValue.replacingOccurrences(of: "1 ", with: "a ")), then keeps resurfacing. Tap Less often to space it out."
            }
        }
    }

    /// How often a to-do repeats.
    enum TodoRepeat: String, CaseIterable, Identifiable {
        case never = "Never"
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"

        var id: String { rawValue }

        var hours: Int? {
            switch self {
            case .never: nil
            case .daily: 24
            case .weekly: 168
            case .monthly: 720
            }
        }
    }

    static func makeNote(content: String, returns: NoteReturn, folder: Folder? = nil, priority: PriorityType = .none, now: Date = Date()) -> Card {
        let defaults = CardOptionsSection.defaults(for: .note)
        return Card(
            createdAt: now,
            cardType: .note,
            priorityTypeRaw: priority,
            content: content,
            isRecurring: returns.isRecurring,
            repeatInterval: returns.hours,
            initialRepeatInterval: returns.hours,
            nextTimeInQueue: now.addingTimeInterval(TimeInterval(returns.hours) * 3600),
            folder: folder,
            skipPolicy: defaults.skipPolicy,
            ratingEasyPolicy: defaults.ratingEasyPolicy,
            ratingMedPolicy: defaults.ratingMedPolicy,
            ratingHardPolicy: defaults.ratingHardPolicy,
            resetRepeatIntervalOnComplete: defaults.resetRepeatIntervalOnComplete,
            skipEnabled: defaults.skipEnabled
        )
    }

    /// New flashcards are ready to study right away, then space out as they're rated.
    static func makeFlashcard(question: String, answer: String, folder: Folder? = nil, priority: PriorityType = .none, now: Date = Date()) -> Card {
        let defaults = CardOptionsSection.defaults(for: .flashcard)
        let hours = defaults.repeatInterval.hours ?? 72
        return Card(
            createdAt: now,
            cardType: .flashcard,
            priorityTypeRaw: priority,
            content: question,
            isRecurring: true,
            repeatInterval: hours,
            initialRepeatInterval: hours,
            nextTimeInQueue: now,
            folder: folder,
            answer: answer.isEmpty ? nil : answer,
            skipPolicy: defaults.skipPolicy,
            ratingEasyPolicy: defaults.ratingEasyPolicy,
            ratingMedPolicy: defaults.ratingMedPolicy,
            ratingHardPolicy: defaults.ratingHardPolicy,
            resetRepeatIntervalOnComplete: defaults.resetRepeatIntervalOnComplete,
            skipEnabled: defaults.skipEnabled
        )
    }

    /// To-dos show up when they're due; a repeating to-do comes back after each completion.
    static func makeTodo(content: String, due: Date, repeatHours: Int?, folder: Folder? = nil, priority: PriorityType = .none, now: Date = Date()) -> Card {
        let defaults = CardOptionsSection.defaults(for: .todo)
        // A one-time to-do has no real interval; 2 days makes Later mean "tomorrow".
        let hours = repeatHours ?? 48
        return Card(
            createdAt: now,
            cardType: .todo,
            priorityTypeRaw: priority,
            content: content,
            isRecurring: repeatHours != nil,
            repeatInterval: hours,
            initialRepeatInterval: hours,
            nextTimeInQueue: due,
            folder: folder,
            skipPolicy: defaults.skipPolicy,
            ratingEasyPolicy: defaults.ratingEasyPolicy,
            ratingMedPolicy: defaults.ratingMedPolicy,
            ratingHardPolicy: defaults.ratingHardPolicy,
            resetRepeatIntervalOnComplete: defaults.resetRepeatIntervalOnComplete,
            skipEnabled: true
        )
    }

    /// A short starter set that teaches each kind of card by using it.
    static func insertExamples(into context: ModelContext, now: Date = Date()) {
        let note = makeNote(
            content: "Notes are for ideas worth meeting again.\n\nThis one came back so you could see how: **Got it** sends it away until next time, **Less often** spaces it out further, and **Add a thought** keeps a dated reflection with it.",
            returns: .month,
            now: now
        )
        note.nextTimeInQueue = now.addingTimeInterval(-60)
        let flashcard = makeFlashcard(
            question: "What do Hard, Good and Easy do in Top Note?",
            answer: "Hard brings a flashcard back sooner. Good and Easy space it out. The time under each button shows exactly when you'll see it again.",
            now: now.addingTimeInterval(-30)
        )
        let capital = makeFlashcard(question: "What is the capital of Australia?", answer: "Canberra", now: now.addingTimeInterval(-20))
        let todo = makeTodo(
            content: "Add the Top Note widget to your Home Screen",
            due: now.addingTimeInterval(-10),
            repeatHours: nil,
            priority: .high,
            now: now
        )
        [note, flashcard, capital, todo].forEach(context.insert)
        try? context.save()
        TopNoteShared.reloadWidgets()
    }
}
