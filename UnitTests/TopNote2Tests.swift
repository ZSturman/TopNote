//
//  TopNote2Tests.swift
//  UnitTests
//
//  Behavior introduced in 2.0: Recallable-style flashcard spacing, interval previews, the 1.x
//  upgrade, deep links, capture defaults and activity stats.
//

@testable import TopNote
import SwiftData
import Foundation
import Testing

@MainActor
@Suite("Top Note 2.0")
struct TopNote2Tests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() throws {
        let schema = Schema([Card.self, Folder.self, CardTag.self])
        container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
    }

    @Test func goodRatingSpacesAFlashcardOut() {
        let now = Date()
        let card = CardFactory.makeFlashcard(question: "Q", answer: "A", now: now)
        #expect(card.repeatInterval == 72)
        card.submitFlashcardRating(.good, at: now)
        #expect(card.repeatInterval == 83, "Good grows 72h by the mild multiplier (1.15)")
        #expect(abs(card.nextTimeInQueue.timeIntervalSince(now) - 83 * 3600) < 1)
    }

    @Test func goodWithNonePolicyKeepsTheInterval() {
        let now = Date()
        let card = CardFactory.makeFlashcard(question: "Q", answer: "A", now: now)
        card.ratingMedPolicy = .none
        card.submitFlashcardRating(.good, at: now)
        #expect(card.repeatInterval == 72)
    }

    @Test func previewMatchesWhatRatingDoes() {
        let now = Date()
        for rating in RatingType.allCases {
            let card = CardFactory.makeFlashcard(question: "Q", answer: "A", now: now)
            card.repeatInterval = 200
            let preview = card.previewIntervalHours(for: rating)
            card.submitFlashcardRating(rating, at: now)
            #expect(card.repeatInterval == preview, "\(rating) preview")
        }
    }

    @Test func skipPreviewMatchesSkip() {
        let now = Date()
        for card in [
            CardFactory.makeNote(content: "N", returns: .month, now: now),
            CardFactory.makeTodo(content: "T", due: now, repeatHours: 168, now: now)
        ] {
            card.nextTimeInQueue = now
            let preview = card.previewSkipHours()
            card.skip(at: now)
            #expect(card.repeatInterval == preview, "\(card.cardType) skip preview")
        }
    }

    @Test func notesComeBackLaterWhenSkipped() {
        let now = Date()
        let note = CardFactory.makeNote(content: "N", returns: .month, now: now)
        note.skip(at: now)
        #expect(note.repeatInterval > 720)
    }

    @Test func oneTimeTodoLaterMeansTomorrow() {
        let now = Date()
        let todo = CardFactory.makeTodo(content: "T", due: now, repeatHours: nil, now: now)
        #expect(!todo.isRecurring)
        todo.skip(at: now)
        #expect(todo.repeatInterval == 24)
    }

    @Test func upgradeAdoptsGoodPolicyOnceForFlashcardsOnly() {
        UserDefaults.standard.removeObject(forKey: "migration.flashcardGoodGrows.v2")
        defer { UserDefaults.standard.set(true, forKey: "migration.flashcardGoodGrows.v2") }
        let legacy = CardFactory.makeFlashcard(question: "Q", answer: "A")
        legacy.ratingMedPolicy = .none
        let note = CardFactory.makeNote(content: "N", returns: .month)
        note.ratingMedPolicy = .none
        context.insert(legacy)
        context.insert(note)
        LibraryMaintenance.upgradeFlashcardGoodPolicy(context: context)
        #expect(legacy.ratingMedPolicy == .mild)
        #expect(note.ratingMedPolicy == .none)
        // Runs once: a later choice of None is respected.
        legacy.ratingMedPolicy = .none
        LibraryMaintenance.upgradeFlashcardGoodPolicy(context: context)
        #expect(legacy.ratingMedPolicy == .none)
    }

    @Test func routesRoundTrip() {
        let id = UUID()
        let routes: [TopNoteRoute] = [.card(id), .add(.todo), .add(nil), .upNext(.flashcard), .upNext(nil), .settings("reminders")]
        for route in routes {
            #expect(TopNoteRoute(url: route.url) == route)
        }
        #expect(TopNoteRoute(url: URL(string: "topnote://card/\(id.uuidString)")!) == .card(id), "1.x widget links still work")
        #expect(TopNoteRoute(url: URL(string: "topnote://study")!) == .upNext(.flashcard))
        #expect(TopNoteRoute(url: URL(string: "https://example.com")!) == nil)
    }

    @Test func remindersLinkFindsCardFromURL() {
        let card = CardFactory.makeTodo(content: "T", due: Date(), repeatHours: nil)
        #expect(RemindersSync.cardID(from: card.url) == card.id)
        #expect(RemindersSync.cardID(from: URL(string: "https://apple.com")) == nil)
    }

    @Test func strengthFollowsInterval() {
        #expect(CardStrength(reviewCount: 0, intervalHours: 9000) == .new)
        #expect(CardStrength(reviewCount: 2, intervalHours: 72) == .learning)
        #expect(CardStrength(reviewCount: 4, intervalHours: 24 * 10) == .familiar)
        #expect(CardStrength(reviewCount: 9, intervalHours: 24 * 60) == .strong)
    }

    @Test func activityStatsCountsTodayAndStreak() {
        let calendar = Calendar.current
        let now = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        let card = CardFactory.makeTodo(content: "T", due: now, repeatHours: 24, now: now)
        card.completes = [now, now.addingTimeInterval(-86_400), now.addingTimeInterval(-2 * 86_400), now.addingTimeInterval(-5 * 86_400)]
        let stats = ActivityStats(cards: [card], now: now, calendar: calendar)
        #expect(stats.handledToday == 1)
        #expect(stats.streakDays == 3)
    }

    @Test func captureDefaultsFitEachKind() {
        let now = Date()
        let note = CardFactory.makeNote(content: "N", returns: .week, now: now)
        #expect(note.nextTimeInQueue > now, "Notes come back later, not immediately")
        let once = CardFactory.makeNote(content: "N", returns: .once, now: now)
        #expect(!once.isRecurring)
        let flashcard = CardFactory.makeFlashcard(question: "Q", answer: "", now: now)
        #expect(flashcard.isEnqueue(currentDate: now), "New flashcards are ready to study")
        #expect(flashcard.answer == nil)
        let todo = CardFactory.makeTodo(content: "T", due: now.addingTimeInterval(3600), repeatHours: 168, now: now)
        #expect(todo.isRecurring && todo.repeatInterval == 168)
        #expect(!todo.isEnqueue(currentDate: now))
    }

    @Test func undoSnapshotRestoresACompletedTodo() {
        let now = Date()
        let todo = CardFactory.makeTodo(content: "T", due: now, repeatHours: nil, now: now)
        context.insert(todo)
        let snapshot = CardUndoSnapshot(todo)
        todo.markAsComplete(at: now)
        #expect(todo.isArchived && todo.isComplete)
        snapshot.restore(todo)
        #expect(!todo.isArchived && !todo.isComplete && todo.completes.isEmpty)
        #expect(todo.isEnqueue(currentDate: now))
    }

    @Test func intervalTextReadsNaturally() {
        #expect(IntervalText.long(hours: 24) == "tomorrow")
        #expect(IntervalText.long(hours: 72) == "in 3 days")
        #expect(IntervalText.long(hours: 168) == "in 7 days")
        #expect(IntervalText.long(hours: 336) == "in 2 weeks")
        #expect(IntervalText.long(hours: 720) == "in a month")
        #expect(IntervalText.short(hours: 83) == "3 days")
    }

    // MARK: - Store recovery

    private func temporaryFile(_ data: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("store-\(UUID().uuidString).store")
        try data.write(to: url)
        return url
    }

    @Test func garbageStoreIsCorrupt() throws {
        let url = try temporaryFile(Data(repeating: 0x41, count: 4096))
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(StoreRecoveryPolicy.storeIsCorrupt(at: url))
        #expect(StoreRecoveryPolicy.shouldSetAside(storeURL: url, isAppExtension: false))
    }

    @Test func extensionNeverSetsAStoreAside() throws {
        let url = try temporaryFile(Data(repeating: 0x41, count: 4096))
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(!StoreRecoveryPolicy.shouldSetAside(storeURL: url, isAppExtension: true))
    }

    @Test func healthyMissingOrUnreadableStoresAreLeftAlone() throws {
        // A real SQLite store made by SwiftData.
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("healthy-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("default.store")
        do {
            let schema = Schema([Card.self, Folder.self, CardTag.self])
            let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none))
            container.mainContext.insert(CardFactory.makeNote(content: "Keep me", returns: .month))
            try container.mainContext.save()
        }
        #expect(!StoreRecoveryPolicy.storeIsCorrupt(at: storeURL))
        // Missing file.
        #expect(!StoreRecoveryPolicy.storeIsCorrupt(at: directory.appendingPathComponent("missing.store")))
        // Unreadable file (like a protected store before first unlock).
        let locked = try temporaryFile(Data(repeating: 0x41, count: 4096))
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: locked.path); try? FileManager.default.removeItem(at: locked) }
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: locked.path)
        #expect(!StoreRecoveryPolicy.storeIsCorrupt(at: locked))
    }

    // MARK: - Welcome

    @Test func welcomeShowsOnceAndPicksByLibrary() {
        let defaults = UserDefaults.standard
        let keys = [WelcomeState.onboardingKey, WelcomeState.whatsNewKey]
        let saved = keys.map { defaults.object(forKey: $0) }
        defer { for (key, value) in zip(keys, saved) { defaults.set(value, forKey: key) } }
        keys.forEach { defaults.removeObject(forKey: $0) }
        #expect(WelcomeState.sheetForLaunch(hasCards: true) == .whatsNew, "1.x users see What's New")
        #expect(WelcomeState.sheetForLaunch(hasCards: false) == .onboarding, "New people see onboarding")
        WelcomeState.markSeen()
        #expect(WelcomeState.sheetForLaunch(hasCards: true) == nil)
        #expect(WelcomeState.sheetForLaunch(hasCards: false) == nil)
    }
}
