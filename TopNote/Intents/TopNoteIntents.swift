//
//  TopNoteIntents.swift
//  TopNote
//
//  Siri, Shortcuts and Spotlight actions. Capture and "what's next" run in the background, so
//  they work from Siri, the Action button and automations without opening the app.
//

import AppIntents
import SwiftData
import SwiftUI

// MARK: - Capture

struct AddNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Note"
    static let description = IntentDescription("Saves a note to Top Note. It comes back to you later so it doesn't get lost.")

    @Parameter(title: "Note", inputOptions: String.IntentInputOptions(multiline: true), requestValueDialog: "What do you want to remember?")
    var text: String

    @Parameter(title: "Bring it back in", default: .month)
    var returns: NoteReturnOption

    init() {}

    static var parameterSummary: some ParameterSummary {
        Summary("Add note \(\.$text), back in \(\.$returns)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<CardEntity> & ProvidesDialog {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw $text.needsValueError("What do you want to remember?") }
        let card = CardFactory.makeNote(content: trimmed, returns: returns.factoryValue)
        try IntentStore.insert(card)
        return .result(value: CardEntity(card: card), dialog: "Saved. It'll come back \(IntervalText.long(hours: card.repeatInterval)).")
    }
}

struct AddTodoIntent: AppIntent {
    static let title: LocalizedStringResource = "Add To-do"
    static let description = IntentDescription("Adds a to-do to Top Note. It shows up when it's due, and in Reminders when sync is on.")

    @Parameter(title: "To-do", requestValueDialog: "What needs doing?")
    var text: String

    @Parameter(title: "Due", description: "Leave empty for now.")
    var due: Date?

    @Parameter(title: "Repeat", default: .never)
    var repeats: TodoRepeatOption

    init() {}

    static var parameterSummary: some ParameterSummary {
        Summary("Add to-do \(\.$text) due \(\.$due)") {
            \.$repeats
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<CardEntity> & ProvidesDialog {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw $text.needsValueError("What needs doing?") }
        let card = CardFactory.makeTodo(content: trimmed, due: due ?? Date(), repeatHours: repeats.factoryValue.hours)
        try IntentStore.insert(card)
        let reminders = RemindersSync.shared
        reminders.refreshAuthorization()
        let addedToReminders = reminders.addsNewTodos && reminders.addReminder(for: card)
        let when = due.map { $0.formatted(.relative(presentation: .named)) } ?? "now"
        return .result(
            value: CardEntity(card: card),
            dialog: addedToReminders ? "Added, due \(when), and in Reminders." : "Added, due \(when)."
        )
    }
}

struct AddFlashcardIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Flashcard"
    static let description = IntentDescription("Adds a flashcard to Top Note. New flashcards are ready to study right away.")

    @Parameter(title: "Question", requestValueDialog: "What's the question?")
    var question: String

    @Parameter(title: "Answer", requestValueDialog: "And the answer?")
    var answer: String

    init() {}

    static var parameterSummary: some ParameterSummary {
        Summary("Add flashcard \(\.$question) with answer \(\.$answer)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<CardEntity> & ProvidesDialog {
        let card = CardFactory.makeFlashcard(
            question: question.trimmingCharacters(in: .whitespacesAndNewlines),
            answer: answer.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        try IntentStore.insert(card)
        return .result(value: CardEntity(card: card), dialog: "Flashcard added. It's ready to study.")
    }
}

// MARK: - What's next

struct WhatsNextIntent: AppIntent {
    static let title: LocalizedStringResource = "What's Next"
    static let description = IntentDescription("Tells you the card that matters right now.")

    @Parameter(title: "Only", description: "Leave empty for any kind of card.")
    var type: CardType?

    init() {}

    static var parameterSummary: some ParameterSummary {
        Summary("What's next in \(\.$type)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<CardEntity?> & ProvidesDialog & ShowsSnippetView {
        let queue = try IntentStore.queue(type: type)
        guard let card = queue.first else {
            return .result(value: nil, dialog: "You're all caught up.", view: WhatsNextSnippet(card: nil, remaining: 0))
        }
        let spoken: IntentDialog
        switch card.cardType {
        case .flashcard: spoken = "Here's a flashcard: \(card.content)"
        case .todo: spoken = "Next to-do: \(card.content)"
        case .note: spoken = "A note for you: \(card.content)"
        }
        return .result(value: CardEntity(card: card), dialog: spoken, view: WhatsNextSnippet(card: CardEntity(card: card), remaining: queue.count - 1))
    }
}

struct ReadyCountIntent: AppIntent {
    static let title: LocalizedStringResource = "Cards Ready"
    static let description = IntentDescription("Counts the cards waiting in Up Next.")

    @Parameter(title: "Only")
    var type: CardType?

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
        let queue = try IntentStore.queue(type: type)
        guard !queue.isEmpty else { return .result(value: 0, dialog: "Nothing's waiting. You're all caught up.") }
        let counts = Dictionary(grouping: queue, by: \.cardType).mapValues(\.count)
        let parts = [CardType.note, .flashcard, .todo].compactMap { kind -> String? in
            guard let count = counts[kind], count > 0 else { return nil }
            return "\(count) \(count == 1 ? kind.rawValue.lowercased() : kind.pluralName.lowercased())"
        }
        return .result(value: queue.count, dialog: "\(queue.count) ready: \(parts.joined(separator: ", ")).")
    }
}

struct StudyFlashcardsIntent: AppIntent {
    static let title: LocalizedStringResource = "Study Flashcards"
    static let description = IntentDescription("Opens Up Next with just your flashcards.")
    static let openAppWhenRun = true

    init() {}

    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(TopNoteRoute.upNext(.flashcard).url))
    }
}

// MARK: - Options

enum NoteReturnOption: String, AppEnum {
    case week, month, threeMonths, sixMonths, once

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Return"
    static let caseDisplayRepresentations: [NoteReturnOption: DisplayRepresentation] = [
        .week: "1 week", .month: "1 month", .threeMonths: "3 months", .sixMonths: "6 months", .once: "Once (then archive)"
    ]

    var factoryValue: CardFactory.NoteReturn {
        switch self {
        case .week: .week
        case .month: .month
        case .threeMonths: .threeMonths
        case .sixMonths: .sixMonths
        case .once: .once
        }
    }
}

enum TodoRepeatOption: String, AppEnum {
    case never, daily, weekly, monthly

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Repeat"
    static let caseDisplayRepresentations: [TodoRepeatOption: DisplayRepresentation] = [
        .never: "Never", .daily: "Daily", .weekly: "Weekly", .monthly: "Monthly"
    ]

    var factoryValue: CardFactory.TodoRepeat {
        switch self {
        case .never: .never
        case .daily: .daily
        case .weekly: .weekly
        case .monthly: .monthly
        }
    }
}

// MARK: - Store access

@MainActor
enum IntentStore {
    /// Tests swap in an in-memory container.
    static var container: ModelContainer = sharedModelContainer

    static func insert(_ card: Card) throws {
        let context = container.mainContext
        context.insert(card)
        try context.save()
        TopNoteShared.reloadWidgets()
    }

    static func queue(type: CardType?, now: Date = Date()) throws -> [Card] {
        let context = container.mainContext
        return try context.fetch(FetchDescriptor<Card>(predicate: #Predicate { $0.deletedAt == nil && $0.isArchived == false }))
            .filter { $0.nextTimeInQueue <= now && (type == nil || $0.cardType == type) }
            .sorted { ($0.priority.sortValue, $0.nextTimeInQueue) < ($1.priority.sortValue, $1.nextTimeInQueue) }
    }
}

struct WhatsNextSnippet: View {
    let card: CardEntity?
    let remaining: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let card {
                Label(card.cardType.rawValue, systemImage: card.cardType.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(card.cardType.tintColor)
                Text(card.content)
                    .font(card.cardType == .note ? .system(.title3, design: .serif) : .title3.weight(.semibold))
                    .lineLimit(6)
                if remaining > 0 {
                    Text("\(remaining) more ready")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Label("All caught up", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

// MARK: - Siri phrases

struct TopNoteShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddNoteIntent(),
            phrases: ["Add a note in \(.applicationName)", "Save a note to \(.applicationName)", "Remember something in \(.applicationName)"],
            shortTitle: "Add Note",
            systemImageName: "text.quote"
        )
        AppShortcut(
            intent: AddTodoIntent(),
            phrases: ["Add a to-do in \(.applicationName)", "Add a task to \(.applicationName)"],
            shortTitle: "Add To-do",
            systemImageName: "checklist"
        )
        AppShortcut(
            intent: AddFlashcardIntent(),
            phrases: ["Add a flashcard in \(.applicationName)", "Make a flashcard in \(.applicationName)"],
            shortTitle: "Add Flashcard",
            systemImageName: "rectangle.on.rectangle.angled"
        )
        AppShortcut(
            intent: WhatsNextIntent(),
            phrases: ["What's next in \(.applicationName)", "What's my top note in \(.applicationName)", "Show my next \(\.$type) in \(.applicationName)"],
            shortTitle: "What's Next",
            systemImageName: "rectangle.stack"
        )
        AppShortcut(
            intent: ReadyCountIntent(),
            phrases: ["How many cards are ready in \(.applicationName)", "How many \(\.$type) are ready in \(.applicationName)"],
            shortTitle: "Cards Ready",
            systemImageName: "number.circle"
        )
        AppShortcut(
            intent: StudyFlashcardsIntent(),
            phrases: ["Study flashcards in \(.applicationName)", "Quiz me with \(.applicationName)"],
            shortTitle: "Study Flashcards",
            systemImageName: "brain.head.profile"
        )
        AppShortcut(
            intent: OpenCaptureIntent(),
            phrases: ["Capture in \(.applicationName)", "New \(\.$type) in \(.applicationName)"],
            shortTitle: "New Card",
            systemImageName: "plus.rectangle.on.rectangle"
        )
    }

    static var shortcutTileColor: ShortcutTileColor { .blue }
}
