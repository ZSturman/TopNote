//
//  OpenTopNoteIntents.swift
//  TopNote
//
//  Intents that open the app somewhere useful. Shared with the widget extension so Control
//  Center controls can use them.
//

import AppIntents
import Foundation
import SwiftData

extension RatingType: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Rating" }
    static var caseDisplayRepresentations: [RatingType: DisplayRepresentation] {
        [
            .hard: DisplayRepresentation(title: "Hard", subtitle: "Bring it back sooner"),
            .good: DisplayRepresentation(title: "Good", subtitle: "Space it out a little"),
            .easy: DisplayRepresentation(title: "Easy", subtitle: "Space it out more")
        ]
    }
}

/// Opens the capture sheet, ready for a note, flashcard or to-do.
struct OpenCaptureIntent: AppIntent {
    static let title: LocalizedStringResource = "New Card"
    static let description = IntentDescription("Opens Top Note ready to capture a note, flashcard or to-do.")
    static let openAppWhenRun = true

    @Parameter(title: "Kind of card", description: "Leave empty to use the kind you used last.")
    var type: CardType?

    init() {}
    init(type: CardType?) { self.type = type }

    static var parameterSummary: some ParameterSummary {
        Summary("New \(\.$type) in Top Note")
    }

    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(TopNoteRoute.add(type).url))
    }
}

/// Opens Up Next, optionally showing one kind of card.
struct OpenUpNextIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Up Next"
    static let description = IntentDescription("Opens Top Note to the card that matters right now.")
    static let openAppWhenRun = true

    @Parameter(title: "Show only")
    var type: CardType?

    init() {}
    init(type: CardType?) { self.type = type }

    static var parameterSummary: some ParameterSummary {
        Summary("Open Up Next showing \(\.$type)")
    }

    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(TopNoteRoute.upNext(type).url))
    }
}

/// Rates a flashcard from Shortcuts.
struct RateFlashcardIntent: AppIntent {
    static let title: LocalizedStringResource = "Rate Flashcard"
    static let description = IntentDescription("Records how well you knew a flashcard. Hard brings it back sooner; Good and Easy space it out.")

    @Parameter(title: "Flashcard")
    var card: CardEntity

    @Parameter(title: "Rating", default: .good)
    var rating: RatingType

    init() {}

    static var parameterSummary: some ParameterSummary {
        Summary("Rate \(\.$card) as \(\.$rating)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = ModelContext(sharedModelContainer)
        guard let model = try fetchCardModel(context, id: card.id), model.cardType == .flashcard else {
            return .result(dialog: "That card isn't a flashcard.")
        }
        model.submitFlashcardRating(rating, at: Date())
        try context.save()
        TopNoteShared.reloadWidgets()
        return .result(dialog: "Rated \(rating.rawValue). You'll see it again \(IntervalText.long(hours: model.repeatInterval)).")
    }
}
