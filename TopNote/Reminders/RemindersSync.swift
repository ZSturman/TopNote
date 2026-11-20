//
//  RemindersSync.swift
//  TopNote
//
//  Two-way link between Top Note to-dos and Apple Reminders.
//
//  A linked reminder carries `topnote://card/<id>` as its URL, which travels with iCloud
//  Reminders, so every device can find the card a reminder belongs to and reminders created by
//  Top Note are never imported twice. Each device keeps the last state both sides agreed on
//  (a baseline) and reconciles with a three-way merge: whichever side changed since the baseline
//  wins, and Top Note wins when both did.
//

import EventKit
import Foundation
import SwiftData
import os.log

@MainActor
final class RemindersSync: ObservableObject {
    static let shared = RemindersSync()

    struct Baseline: Codable, Equatable {
        var title: String
        var completed: Bool
        var due: Date?
        var completionCount: Int
    }

    struct Report: Equatable {
        var imported = 0
        var updatedCards = 0
        var updatedReminders = 0
        var summary: String {
            if imported == 0 && updatedCards == 0 && updatedReminders == 0 { return "Everything is up to date." }
            var parts: [String] = []
            if imported > 0 { parts.append("imported \(imported) reminder\(imported == 1 ? "" : "s")") }
            if updatedCards > 0 { parts.append("updated \(updatedCards) to-do\(updatedCards == 1 ? "" : "s")") }
            if updatedReminders > 0 { parts.append("updated \(updatedReminders) reminder\(updatedReminders == 1 ? "" : "s")") }
            return parts.joined(separator: ", ").prefix(1).uppercased() + parts.joined(separator: ", ").dropFirst() + "."
        }
    }

    let store: EKEventStore
    private let defaults: UserDefaults
    private let logger = Logger(subsystem: "com.zacharysturman.topnote", category: "Reminders")
    private var changeObserver: NSObjectProtocol?
    private var isSyncing = false

    @Published private(set) var authorization: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
    @Published private(set) var lists: [EKCalendar] = []
    @Published private(set) var lastReport: Report?
    @Published private(set) var lastSyncDate: Date?

    /// Sync is on once someone connects a list.
    @Published var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Keys.enabled) }
    }
    /// The Reminders list linked to Top Note to-dos.
    @Published var listID: String? {
        didSet { defaults.set(listID, forKey: Keys.listID) }
    }
    /// New, unlinked reminders in the list become Top Note to-dos.
    @Published var importsNewReminders: Bool {
        didSet { defaults.set(importsNewReminders, forKey: Keys.importNew) }
    }
    /// New to-dos created in Top Note are added to the list by default.
    @Published var addsNewTodos: Bool {
        didSet { defaults.set(addsNewTodos, forKey: Keys.addNew) }
    }

    private enum Keys {
        static let enabled = "reminders.enabled"
        static let listID = "reminders.listID"
        static let importNew = "reminders.importNew"
        static let addNew = "reminders.addNewTodos"
        static let baselines = "reminders.baselines"
    }

    /// Tests pass their own store and defaults so they never touch the app's settings.
    init(store: EKEventStore = EKEventStore(), defaults: UserDefaults = .standard) {
        self.store = store
        self.defaults = defaults
        isEnabled = defaults.bool(forKey: Keys.enabled)
        listID = defaults.string(forKey: Keys.listID)
        importsNewReminders = defaults.object(forKey: Keys.importNew) as? Bool ?? true
        addsNewTodos = defaults.object(forKey: Keys.addNew) as? Bool ?? true
    }

    var hasAccess: Bool { authorization == .fullAccess }
    var isActive: Bool { isEnabled && hasAccess && selectedList != nil }

    var selectedList: EKCalendar? {
        guard let listID else { return nil }
        return store.calendar(withIdentifier: listID)
    }

    // MARK: - Access and lists

    func requestAccess() async -> Bool {
        do {
            let granted = try await store.requestFullAccessToReminders()
            refreshAuthorization()
            return granted
        } catch {
            logger.error("Reminders access request failed: \(error.localizedDescription)")
            refreshAuthorization()
            return false
        }
    }

    func refreshAuthorization() {
        authorization = EKEventStore.authorizationStatus(for: .reminder)
        if hasAccess {
            store.refreshSourcesIfNecessary()
            lists = store.calendars(for: .reminder).sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        } else {
            lists = []
        }
    }

    /// Connects Top Note to a list, creating a "Top Note" list when none is chosen.
    func connect(listID chosen: String?) throws {
        if let chosen {
            listID = chosen
        } else if let existing = lists.first(where: { $0.title == "Top Note" }) {
            listID = existing.calendarIdentifier
        } else {
            let list = EKCalendar(for: .reminder, eventStore: store)
            list.title = "Top Note"
            list.source = store.defaultCalendarForNewReminders()?.source
                ?? store.sources.first(where: { $0.sourceType == .calDAV || $0.sourceType == .local })
            try store.saveCalendar(list, commit: true)
            listID = list.calendarIdentifier
            refreshAuthorization()
        }
        isEnabled = true
    }

    func disconnect() {
        isEnabled = false
        saveBaselines([:])
    }

    /// Starts listening for changes made in the Reminders app.
    func startObserving(container: ModelContainer) {
        refreshAuthorization()
        guard changeObserver == nil else { return }
        changeObserver = NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: store, queue: .main) { [weak self] _ in
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1))
                _ = await self?.sync(context: container.mainContext)
            }
        }
    }

    // MARK: - Linking

    /// Adds a reminder for a to-do created in Top Note.
    @discardableResult
    func addReminder(for card: Card) -> Bool {
        guard isActive, card.cardType == .todo, let list = selectedList else { return false }
        let reminder = EKReminder(eventStore: store)
        reminder.calendar = list
        reminder.title = card.content
        reminder.url = card.url
        reminder.priority = Self.reminderPriority(card.priority)
        if card.nextTimeInQueue != .distantFuture {
            reminder.dueDateComponents = Self.components(card.nextTimeInQueue)
        }
        do {
            try store.save(reminder, commit: true)
            var baselines = loadBaselines()
            baselines[card.id] = Baseline(title: card.content, completed: false, due: card.nextTimeInQueue, completionCount: card.completes.count)
            saveBaselines(baselines)
            return true
        } catch {
            logger.error("Could not add reminder: \(error.localizedDescription)")
            return false
        }
    }

    func isLinked(_ card: Card) -> Bool {
        loadBaselines()[card.id] != nil
    }

    // MARK: - Reconcile

    /// Reconciles the linked list with Top Note. Safe to call often.
    @discardableResult
    func sync(context: ModelContext, now: Date = Date()) async -> Report {
        guard isActive, !isSyncing, let list = selectedList else { return Report() }
        isSyncing = true
        defer { isSyncing = false }

        let reminders = await fetchReminders(in: list)
        var baselines = loadBaselines()
        var report = Report()

        let todos = (try? context.fetch(FetchDescriptor<Card>())) ?? []
        let cardsByID = Dictionary(todos.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var seenCardIDs = Set<UUID>()

        for reminder in reminders {
            if let cardID = Self.cardID(from: reminder.url) {
                guard let card = cardsByID[cardID], card.cardType == .todo, !card.isDeleted else { continue }
                seenCardIDs.insert(cardID)
                let baseline = baselines[cardID] ?? Baseline(
                    title: reminder.title ?? card.content,
                    completed: reminder.isCompleted,
                    due: Self.date(of: reminder),
                    completionCount: card.completes.count
                )
                let outcome = reconcile(card: card, reminder: reminder, baseline: baseline, now: now)
                if outcome.cardChanged { report.updatedCards += 1 }
                if outcome.reminderChanged {
                    report.updatedReminders += 1
                    try? store.save(reminder, commit: false)
                }
                baselines[cardID] = outcome.baseline
            } else if importsNewReminders, !reminder.isCompleted,
                      let title = reminder.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
                let card = CardFactory.makeTodo(
                    content: title,
                    due: Self.date(of: reminder) ?? now,
                    repeatHours: nil,
                    priority: Self.cardPriority(reminder.priority)
                )
                context.insert(card)
                reminder.url = card.url
                try? store.save(reminder, commit: false)
                baselines[card.id] = Baseline(title: title, completed: false, due: card.nextTimeInQueue, completionCount: 0)
                seenCardIDs.insert(card.id)
                report.imported += 1
            }
        }

        // A linked reminder deleted in Reminders leaves its to-do in place, unlinked.
        for cardID in baselines.keys where !seenCardIDs.contains(cardID) {
            baselines[cardID] = nil
        }

        do {
            try store.commit()
            try context.save()
        } catch {
            logger.error("Reminders sync save failed: \(error.localizedDescription)")
        }
        saveBaselines(baselines)
        lastReport = report
        lastSyncDate = now
        if report != Report() { TopNoteShared.reloadWidgets() }
        return report
    }

    private struct Outcome {
        var baseline: Baseline
        var cardChanged = false
        var reminderChanged = false
    }

    private func reconcile(card: Card, reminder: EKReminder, baseline: Baseline, now: Date) -> Outcome {
        var outcome = Outcome(baseline: baseline)

        // Title
        let reminderTitle = reminder.title ?? ""
        if card.content != baseline.title {
            if reminderTitle != card.content {
                reminder.title = card.content
                outcome.reminderChanged = true
            }
        } else if reminderTitle != baseline.title, !reminderTitle.isEmpty {
            card.content = reminderTitle
            outcome.cardChanged = true
        }

        // Completion
        let completedInApp = card.completes.count > baseline.completionCount
        let completedInReminders = reminder.isCompleted && !baseline.completed
        let reopenedInReminders = !reminder.isCompleted && baseline.completed
        if completedInApp {
            if card.isRecurring {
                if reminder.isCompleted { reminder.isCompleted = false }
                reminder.dueDateComponents = Self.components(card.nextTimeInQueue)
            } else if !reminder.isCompleted {
                reminder.isCompleted = true
            }
            outcome.reminderChanged = true
        } else if completedInReminders {
            card.markAsComplete(at: reminder.completionDate ?? now)
            outcome.cardChanged = true
            if card.isRecurring {
                reminder.isCompleted = false
                reminder.dueDateComponents = Self.components(card.nextTimeInQueue)
                outcome.reminderChanged = true
            }
        } else if reopenedInReminders, card.isComplete {
            card.markAsNotComplete(at: now)
            card.unarchive(at: now)
            card.nextTimeInQueue = Self.date(of: reminder) ?? now
            outcome.cardChanged = true
        }

        // Due date (only while the to-do is active)
        if !card.isArchived, !reminder.isCompleted {
            let reminderDue = Self.date(of: reminder)
            let cardMoved = !Self.sameMinute(card.nextTimeInQueue, baseline.due)
            let reminderMoved = !Self.sameMinute(reminderDue, baseline.due)
            if cardMoved || completedInApp {
                if !Self.sameMinute(reminderDue, card.nextTimeInQueue) {
                    reminder.dueDateComponents = Self.components(card.nextTimeInQueue)
                    outcome.reminderChanged = true
                }
            } else if reminderMoved, let reminderDue {
                card.nextTimeInQueue = reminderDue
                outcome.cardChanged = true
            }
        }

        outcome.baseline = Baseline(
            title: card.content,
            completed: reminder.isCompleted,
            due: card.isArchived ? nil : card.nextTimeInQueue,
            completionCount: card.completes.count
        )
        return outcome
    }

    // MARK: - Helpers

    private func fetchReminders(in list: EKCalendar) async -> [EKReminder] {
        let predicate = store.predicateForReminders(in: [list])
        return await withCheckedContinuation { continuation in
            store.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }

    private func loadBaselines() -> [UUID: Baseline] {
        guard let data = defaults.data(forKey: Keys.baselines),
              let decoded = try? JSONDecoder().decode([String: Baseline].self, from: data) else { return [:] }
        return Dictionary(uniqueKeysWithValues: decoded.compactMap { key, value in UUID(uuidString: key).map { ($0, value) } })
    }

    private func saveBaselines(_ baselines: [UUID: Baseline]) {
        let encoded = Dictionary(uniqueKeysWithValues: baselines.map { ($0.key.uuidString, $0.value) })
        defaults.set(try? JSONEncoder().encode(encoded), forKey: Keys.baselines)
    }

    static func cardID(from url: URL?) -> UUID? {
        guard let url, case .card(let id)? = TopNoteRoute(url: url) else { return nil }
        return id
    }

    /// A reminder's due date. EventKit's components usually carry no calendar, so
    /// `DateComponents.date` would be nil; resolve them in the current calendar instead.
    static func date(of reminder: EKReminder) -> Date? {
        guard let components = reminder.dueDateComponents else { return nil }
        return (components.calendar ?? Calendar.current).date(from: components)
    }

    static func components(_ date: Date) -> DateComponents {
        Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    }

    static func sameMinute(_ lhs: Date?, _ rhs: Date?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil): return true
        case let (l?, r?): return abs(l.timeIntervalSince(r)) < 60
        default: return false
        }
    }

    static func reminderPriority(_ priority: PriorityType) -> Int {
        switch priority {
        case .high: 1
        case .med: 5
        case .low: 9
        case .none: 0
        }
    }

    static func cardPriority(_ priority: Int) -> PriorityType {
        switch priority {
        case 1...4: .high
        case 5: .med
        case 6...9: .low
        default: .none
        }
    }
}
