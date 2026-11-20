//
//  AppIntentTests.swift
//  UnitTests
//
//  Runs the Siri and Shortcuts intents against an in-memory library.
//

@testable import TopNote
import AppIntents
import SwiftData
import Foundation
import Testing

@MainActor
@Suite("App Intents", .serialized)
struct AppIntentTests {
    let container: ModelContainer

    init() throws {
        let schema = Schema([Card.self, Folder.self, CardTag.self])
        container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        IntentStore.container = container
    }

    private func cards() throws -> [Card] { try container.mainContext.fetch(FetchDescriptor<Card>()) }

    @Test func addNoteSavesANoteThatComesBackLater() async throws {
        var intent = AddNoteIntent()
        intent.text = "  Read more poetry  "
        intent.returns = .week
        _ = try await intent.perform()
        let note = try #require(try cards().first)
        #expect(note.cardType == .note && note.content == "Read more poetry")
        #expect(note.repeatInterval == 168 && !note.isEnqueue(currentDate: Date()))
    }

    @Test func addTodoUsesDueDateAndRepeat() async throws {
        var intent = AddTodoIntent()
        intent.text = "Take out recycling"
        intent.due = Date().addingTimeInterval(86_400)
        intent.repeats = .weekly
        _ = try await intent.perform()
        let todo = try #require(try cards().first)
        #expect(todo.cardType == .todo && todo.isRecurring && todo.repeatInterval == 168)
        #expect(!todo.isEnqueue(currentDate: Date()))
    }

    @Test func addFlashcardIsReadyNow() async throws {
        var intent = AddFlashcardIntent()
        intent.question = "Capital of Peru?"
        intent.answer = "Lima"
        _ = try await intent.perform()
        let card = try #require(try cards().first)
        #expect(card.cardType == .flashcard && card.answer == "Lima" && card.isEnqueue(currentDate: Date()))
    }

    @Test func whatsNextAndCountFollowUpNextOrder() async throws {
        let context = container.mainContext
        let low = CardFactory.makeTodo(content: "Low", due: Date().addingTimeInterval(-7200), repeatHours: nil)
        let high = CardFactory.makeTodo(content: "High", due: Date().addingTimeInterval(-60), repeatHours: nil, priority: .high)
        let later = CardFactory.makeNote(content: "Later", returns: .month)
        [low, high, later].forEach(context.insert)
        try context.save()
        #expect(try IntentStore.queue(type: nil).map(\.content) == ["High", "Low"])
        #expect(try IntentStore.queue(type: .note).isEmpty)
        var count = ReadyCountIntent()
        count.type = nil
        _ = try await count.perform()
    }

    @Test func captureAndUpNextIntentsOpenTheRightPlaces() {
        #expect(TopNoteRoute(url: TopNoteRoute.add(.todo).url) == .add(.todo))
        #expect(TopNoteRoute(url: TopNoteRoute.upNext(.flashcard).url) == .upNext(.flashcard))
    }
}
