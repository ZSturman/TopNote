//
//  LibraryMaintenance.swift
//  TopNote
//
//  One-time upgrades and small bookkeeping that run when the app opens.
//

import Foundation
import SwiftData

enum LibraryMaintenance {
    private static let goodGrowsKey = "migration.flashcardGoodGrows.v2"

    @MainActor
    static func runOnLaunch(context: ModelContext) {
        upgradeFlashcardGoodPolicy(context: context)
    }

    /// In 1.x a Good rating never moved a flashcard, so cards rated Good stayed on the same
    /// interval forever. 2.0 follows Recallable: Good spaces a card out a little. 1.x offered no
    /// way to change Good, so every flashcard still on the 1.x value adopts the new default once.
    @MainActor
    static func upgradeFlashcardGoodPolicy(context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: goodGrowsKey) else { return }
        let flashcardType = CardType.flashcard.rawValue
        let descriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.cardTypeRaw == flashcardType })
        guard let flashcards = try? context.fetch(descriptor) else { return }
        var changed = 0
        for card in flashcards where card.ratingMedPolicy == .none {
            card.ratingMedPolicy = .mild
            changed += 1
        }
        do {
            if changed > 0 { try context.save() }
            defaults.set(true, forKey: goodGrowsKey)
            TopNoteLogger.migration.info("Flashcard Good policy upgraded on \(changed) cards")
        } catch {
            TopNoteLogger.migration.error("Flashcard Good policy upgrade failed: \(error.localizedDescription)")
        }
    }
}

/// Today's progress and the run of days with something handled, computed from card histories.
struct ActivityStats: Equatable {
    var handledToday = 0
    var streakDays = 0
    var studiedToday = 0

    init() {}

    init(cards: [Card], now: Date = Date(), calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: now)
        var days = Set<Date>()
        for card in cards where !card.isDeleted {
            let ratings = card.ratingEvents.map(\.date)
            for date in ratings + card.completes + card.removals {
                days.insert(calendar.startOfDay(for: date))
                if date >= today { handledToday += 1 }
            }
            studiedToday += ratings.filter { $0 >= today }.count
        }
        var day = today
        if !days.contains(day), let yesterday = calendar.date(byAdding: .day, value: -1, to: day) { day = yesterday }
        while days.contains(day) {
            streakDays += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
    }
}
