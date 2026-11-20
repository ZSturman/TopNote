//
//  CardEntityQuery.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import AppIntents
import SwiftData

/// Finds cards for Shortcuts and Siri: by identifier, by text, or suggested (ready now first).
struct CardEntityQuery: EntityStringQuery {
    let container = sharedModelContainer

    @MainActor
    private func activeCards() throws -> [Card] {
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<Card>()).filter { !$0.isDeleted }
    }

    @MainActor
    func entities(for identifiers: [CardEntity.ID]) async throws -> [CardEntity] {
        let context = ModelContext(container)
        let idSet = Set(identifiers)
        let cards = identifiers.isEmpty
            ? try context.fetch(FetchDescriptor<Card>())
            : try context.fetch(FetchDescriptor<Card>()).filter { idSet.contains($0.id) }
        return cards.map(CardEntity.init(card:))
    }

    @MainActor
    func entities(matching string: String) async throws -> [CardEntity] {
        try activeCards()
            .filter { $0.content.localizedCaseInsensitiveContains(string) || ($0.answer ?? "").localizedCaseInsensitiveContains(string) }
            .prefix(50)
            .map(CardEntity.init(card:))
    }

    @MainActor
    func suggestedEntities() async throws -> [CardEntity] {
        let now = Date()
        return try activeCards()
            .filter { !$0.isArchived }
            .sorted { ($0.isEnqueue(currentDate: now) ? 0 : 1, $0.priority.sortValue, $0.nextTimeInQueue) < ($1.isEnqueue(currentDate: now) ? 0 : 1, $1.priority.sortValue, $1.nextTimeInQueue) }
            .prefix(30)
            .map(CardEntity.init(card:))
    }
}
