//
//  RemindersSyncTests.swift
//  UnitTests
//
//  Integration tests against real EventKit. Each test makes its own disposable Reminders list
//  ("Top Note QA …"), its own defaults suite and an in-memory library, and deletes the list after.
//  Needs Reminders access for the host app (simulator: `xcrun simctl privacy <udid> grant reminders zacharysturman.TopNote`).
//

@testable import TopNote
import EventKit
import SwiftData
import Foundation
import Testing

@MainActor
@Suite("Reminders sync", .serialized)
final class RemindersSyncTests {
    let store = EKEventStore()
    let defaults: UserDefaults
    let suiteName = "RemindersSyncTests.\(UUID().uuidString)"
    let sync: RemindersSync
    let container: ModelContainer
    var context: ModelContext { container.mainContext }
    var list: EKCalendar!

    init() throws {
        defaults = UserDefaults(suiteName: suiteName)!
        sync = RemindersSync(store: store, defaults: defaults)
        let schema = Schema([Card.self, Folder.self, CardTag.self])
        container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        sync.refreshAuthorization()
        guard sync.hasAccess else { return }
        let list = EKCalendar(for: .reminder, eventStore: store)
        list.title = "Top Note QA \(UUID().uuidString.prefix(6))"
        list.source = store.defaultCalendarForNewReminders()?.source ?? store.sources.first { $0.sourceType == .local || $0.sourceType == .calDAV }
        try store.saveCalendar(list, commit: true)
        self.list = list
        try sync.connect(listID: list.calendarIdentifier)
    }

    deinit {
        let store = store, list = list, suiteName = suiteName
        if let list { try? store.removeCalendar(list, commit: true) }
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    private func requireAccess() throws {
        try #require(sync.hasAccess, "Grant Reminders access to the test host first")
    }

    private func reminders() async -> [EKReminder] {
        await withCheckedContinuation { continuation in
            store.fetchReminders(matching: store.predicateForReminders(in: [list])) { continuation.resume(returning: $0 ?? []) }
        }
    }

    private func addReminder(_ title: String, due: Date? = nil) throws -> EKReminder {
        let reminder = EKReminder(eventStore: store)
        reminder.calendar = list
        reminder.title = title
        if let due { reminder.dueDateComponents = RemindersSync.components(due) }
        try store.save(reminder, commit: true)
        return reminder
    }

    private func cards() throws -> [Card] {
        try context.fetch(FetchDescriptor<Card>())
    }

    private func linkedTodo(_ title: String, due: Date = Date().addingTimeInterval(-60), repeatHours: Int? = nil) throws -> Card {
        let card = CardFactory.makeTodo(content: title, due: due, repeatHours: repeatHours)
        context.insert(card)
        try context.save()
        #expect(sync.addReminder(for: card))
        return card
    }

    // MARK: - Creating and importing

    @Test func newTodoCreatesLinkedReminder() async throws {
        try requireAccess()
        let due = Date().addingTimeInterval(3 * 3600)
        let card = try linkedTodo("Buy stamps", due: due)
        let found = await reminders()
        #expect(found.count == 1)
        #expect(found.first?.title == "Buy stamps")
        #expect(found.first?.url == card.url)
        #expect(RemindersSync.sameMinute(RemindersSync.date(of: found.first!), due))
        #expect(sync.isLinked(card))
    }

    @Test func newReminderIsImportedOnceWithItsDueDate() async throws {
        try requireAccess()
        let due = Date().addingTimeInterval(86_400)
        _ = try addReminder("Call the plumber", due: due)
        let first = await sync.sync(context: context)
        #expect(first.imported == 1)
        let imported = try #require(try cards().first)
        #expect(imported.content == "Call the plumber")
        #expect(imported.cardType == .todo)
        #expect(RemindersSync.sameMinute(imported.nextTimeInQueue, due), "Imported to-do keeps the reminder's due date")
        // Syncing again, or with a second device's baselines, never imports it twice.
        let second = await sync.sync(context: context)
        #expect(second.imported == 0)
        let otherDevice = RemindersSync(store: store, defaults: UserDefaults(suiteName: suiteName + ".other")!)
        try otherDevice.connect(listID: list.calendarIdentifier)
        _ = await otherDevice.sync(context: context)
        #expect(try cards().count == 1)
        UserDefaults().removePersistentDomain(forName: suiteName + ".other")
    }

    @Test func completedRemindersAreNotImported() async throws {
        try requireAccess()
        let done = try addReminder("Already done")
        done.isCompleted = true
        try store.save(done, commit: true)
        let report = await sync.sync(context: context)
        #expect(report.imported == 0)
        #expect(try cards().isEmpty)
    }

    // MARK: - Titles and due dates

    @Test func titleEditedInRemindersUpdatesCard() async throws {
        try requireAccess()
        let card = try linkedTodo("Draft")
        let reminder = try #require(await reminders().first)
        reminder.title = "Draft the newsletter"
        try store.save(reminder, commit: true)
        _ = await sync.sync(context: context)
        #expect(card.content == "Draft the newsletter")
    }

    @Test func titleEditedInAppUpdatesReminder() async throws {
        try requireAccess()
        let card = try linkedTodo("Draft")
        card.content = "Draft the report"
        _ = await sync.sync(context: context)
        #expect(await reminders().first?.title == "Draft the report")
    }

    @Test func bothSidesEditedTopNoteWins() async throws {
        try requireAccess()
        let card = try linkedTodo("Original")
        let reminder = try #require(await reminders().first)
        reminder.title = "Reminders edit"
        try store.save(reminder, commit: true)
        card.content = "Top Note edit"
        _ = await sync.sync(context: context)
        #expect(card.content == "Top Note edit")
        #expect(await reminders().first?.title == "Top Note edit")
    }

    @Test func dueDateMovedInRemindersMovesCard() async throws {
        try requireAccess()
        let card = try linkedTodo("Renew license", due: Date().addingTimeInterval(3600))
        let newDue = Date().addingTimeInterval(5 * 86_400)
        let reminder = try #require(await reminders().first)
        reminder.dueDateComponents = RemindersSync.components(newDue)
        try store.save(reminder, commit: true)
        _ = await sync.sync(context: context)
        #expect(RemindersSync.sameMinute(card.nextTimeInQueue, newDue))
    }

    @Test func dueDateMovedInAppMovesReminder() async throws {
        try requireAccess()
        let card = try linkedTodo("Renew license", due: Date().addingTimeInterval(3600))
        card.skip(at: Date())
        _ = await sync.sync(context: context)
        let reminder = try #require(await reminders().first)
        #expect(RemindersSync.sameMinute(RemindersSync.date(of: reminder), card.nextTimeInQueue))
    }

    // MARK: - Completion

    @Test func completingInRemindersCompletesOneTimeTodo() async throws {
        try requireAccess()
        let card = try linkedTodo("Return library books")
        let reminder = try #require(await reminders().first)
        reminder.isCompleted = true
        try store.save(reminder, commit: true)
        _ = await sync.sync(context: context)
        #expect(card.isComplete && card.isArchived)
    }

    @Test func completingInAppCompletesReminder() async throws {
        try requireAccess()
        let card = try linkedTodo("Return library books")
        card.markAsComplete(at: Date())
        _ = await sync.sync(context: context)
        #expect(await reminders().first?.isCompleted == true)
    }

    @Test func completingRepeatingTodoInRemindersAdvancesBoth() async throws {
        try requireAccess()
        let card = try linkedTodo("Water the plants", repeatHours: 168)
        let reminder = try #require(await reminders().first)
        reminder.isCompleted = true
        try store.save(reminder, commit: true)
        _ = await sync.sync(context: context)
        #expect(card.completes.count == 1)
        #expect(!card.isArchived)
        #expect(card.nextTimeInQueue > Date().addingTimeInterval(6 * 86_400))
        let after = try #require(await reminders().first)
        #expect(!after.isCompleted, "A repeating reminder reopens for its next time")
        #expect(RemindersSync.sameMinute(RemindersSync.date(of: after), card.nextTimeInQueue))
        // A further sync makes no more changes.
        let quiet = await sync.sync(context: context)
        #expect(quiet == RemindersSync.Report())
    }

    @Test func reopeningInRemindersReturnsTodo() async throws {
        try requireAccess()
        let card = try linkedTodo("Pay rent")
        card.markAsComplete(at: Date())
        _ = await sync.sync(context: context)
        let reminder = try #require(await reminders().first)
        reminder.isCompleted = false
        try store.save(reminder, commit: true)
        _ = await sync.sync(context: context)
        #expect(!card.isComplete && !card.isArchived)
        #expect(card.isEnqueue(currentDate: Date().addingTimeInterval(60)))
    }

    // MARK: - Offline, deletion

    @Test func changesMadeWhileOfflineReconcileOnReconnect() async throws {
        try requireAccess()
        let renamed = try linkedTodo("A")
        let completed = try linkedTodo("B")
        // Offline: sync is off while both sides change.
        sync.isEnabled = false
        renamed.content = "A, renamed in Top Note"
        let fromReminders = try #require(await reminders().first { $0.title == "B" })
        fromReminders.isCompleted = true
        try store.save(fromReminders, commit: true)
        _ = try addReminder("C, added while offline")
        #expect(await sync.sync(context: context) == RemindersSync.Report(), "Nothing syncs while off")
        // Reconnect.
        sync.isEnabled = true
        let report = await sync.sync(context: context)
        #expect(report.imported == 1)
        #expect(await reminders().contains { $0.title == "A, renamed in Top Note" })
        #expect(completed.isComplete)
        #expect(try cards().contains { $0.content == "C, added while offline" })
        #expect(try cards().count == 3)
    }

    @Test func deletingReminderUnlinksButKeepsTodo() async throws {
        try requireAccess()
        let card = try linkedTodo("Keep me")
        let reminder = try #require(await reminders().first)
        try store.remove(reminder, commit: true)
        _ = await sync.sync(context: context)
        #expect(!sync.isLinked(card))
        #expect(try cards().contains { $0.id == card.id && !$0.isDeleted })
    }

    @Test func undoWithinWindowDoesNotReachReminders() async throws {
        try requireAccess()
        let card = try linkedTodo("Undo me")
        let snapshot = CardUndoSnapshot(card)
        card.markAsComplete(at: Date())
        snapshot.restore(card)
        _ = await sync.sync(context: context)
        #expect(await reminders().first?.isCompleted == false)
        #expect(!card.isComplete)
    }
}
