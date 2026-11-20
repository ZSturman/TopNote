//
//  ScreenshotData.swift
//  TopNote
//
//  A realistic library for App Store screenshots and UI tests. Only ever inserted into the
//  throwaway in-memory store (`-TopNoteInMemoryStore`), never into someone's library.
//

import Foundation
import SwiftData

enum ScreenshotData {
    @MainActor
    static func insert(into container: ModelContainer, now: Date = Date()) {
        guard TopNoteShared.usesInMemoryStore else { return }
        let context = container.mainContext
        guard ((try? context.fetchCount(FetchDescriptor<Card>())) ?? 0) == 0 else { return }

        func ago(days: Double) -> Date { now.addingTimeInterval(-days * 86_400) }
        func ahead(days: Double) -> Date { now.addingTimeInterval(days * 86_400) }

        let ideas = Folder(name: "Ideas")
        let spanish = Folder(name: "Spanish")
        let home = Folder(name: "Home")
        let work = Folder(name: "Work")
        [ideas, spanish, home, work].forEach(context.insert)

        // Notes
        let quote = CardFactory.makeNote(
            content: "“We are what we repeatedly do. Excellence, then, is not an act, but a habit.”\n\nWill Durant, summarizing Aristotle",
            returns: .month, folder: ideas, now: ago(days: 120)
        )
        quote.nextTimeInQueue = ago(days: 0.02)
        quote.removals = [ago(days: 90), ago(days: 60), ago(days: 30)]
        quote.content += "\n\n— \(ago(days: 30).formatted(date: .abbreviated, time: .omitted)): Started the 6 a.m. walk because of this."

        let appIdea = CardFactory.makeNote(
            content: "**App idea:** a plant journal that reminds you to water based on the weather, not a timer.",
            returns: .threeMonths, folder: ideas, now: ago(days: 40)
        )
        appIdea.nextTimeInQueue = ago(days: 0.5)

        let gift = CardFactory.makeNote(
            content: "Mom mentioned she wants to learn watercolor. Birthday is in March.",
            returns: .month, folder: home, now: ago(days: 20)
        )
        gift.nextTimeInQueue = ahead(days: 9)

        // Flashcards
        let flashcards: [(String, String, Folder?, Int, Double)] = [
            ("How do you say “to remember” in Spanish?", "recordar", spanish, 2, -0.6),
            ("What is the powerhouse of the cell?", "The mitochondrion. It makes most of the cell's ATP.", nil, 5, -0.2),
            ("¿Dónde está la biblioteca?", "Where is the library?", spanish, 1, -0.3),
            ("In what year did the Apollo 11 crew land on the Moon?", "1969", nil, 8, -0.4),
            ("What does “madrugar” mean?", "To get up early", spanish, 2, 2),
            ("What is the speed of light in a vacuum?", "About 299,792 km per second", nil, 0, 4)
        ]
        for (question, answer, folder, reviews, dueInDays) in flashcards {
            let card = CardFactory.makeFlashcard(question: question, answer: answer, folder: folder, now: ago(days: 60))
            card.rating = (0..<reviews).map { [($0 % 4 == 3 ? RatingType.hard : .good): ago(days: Double(50 - $0 * 5))] }
            card.repeatInterval = reviews == 0 ? 72 : min(48 * (reviews + 1), 2000)
            card.nextTimeInQueue = dueInDays < 0 ? now.addingTimeInterval(dueInDays * 3600) : ahead(days: dueInDays)
            context.insert(card)
        }

        // To-dos
        let passport = CardFactory.makeTodo(content: "Renew passport before the June trip", due: ago(days: 1), repeatHours: nil, folder: home, priority: .high, now: ago(days: 10))
        let plants = CardFactory.makeTodo(content: "Water the plants", due: ago(days: 0.1), repeatHours: 168, folder: home, now: ago(days: 30))
        plants.completes = [ago(days: 7.1), ago(days: 14.2), ago(days: 21)]
        let review = CardFactory.makeTodo(content: "Send the Q3 review notes to Priya", due: ago(days: 0.2), repeatHours: nil, folder: work, priority: .med, now: ago(days: 2))
        let dentist = CardFactory.makeTodo(content: "Book a dentist appointment", due: ahead(days: 3), repeatHours: nil, folder: home, now: ago(days: 1))

        [quote, appIdea, gift, passport, plants, review, dentist].forEach(context.insert)

        // A little history so Up Next shows a streak.
        appIdea.removals = [ago(days: 1), ago(days: 2)]
        dentist.skips = [ago(days: 3)]
        try? context.save()
    }
}
