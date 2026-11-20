//
//  NextCardIntent.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import WidgetKit
import AppIntents
import SwiftData

struct NextCardIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Card as Seen"
    static var description = IntentDescription("Sends a note or card away until it's next due, like Got it in the app.")

    @Parameter(title: "Card")
    var card: CardEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Mark \(\.$card) as seen")
    }

    init(card: CardEntity) { self.card = card }
    init() {}

    func perform() async throws -> some IntentResult {
        try await withSharedContext { context in
            guard let cardModel = try fetchCardModel(context, id: card.id) else { return }
            cardModel.next(at: Date())
            try? context.save()
        }

        TopNoteShared.reloadWidgets()
        return .result()
    }
}
