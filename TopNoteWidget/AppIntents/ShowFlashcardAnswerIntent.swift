//
//  ShowFlashcardAnswerIntent.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import WidgetKit
import AppIntents
import SwiftData

struct ShowFlashcardAnswer: AppIntent {
    static var title: LocalizedStringResource = "Show Back"

    @Parameter(title: "Card")
    var card: CardEntity

    @Parameter(title: "Widget ID")
    var widgetID: String

    init(card: CardEntity, widgetID: String) {
        self.card = card
        self.widgetID = widgetID
    }

    init() {}

    func perform() async throws -> some IntentResult {
        // Widget-instance flip state
        WidgetStateManager.shared.setFlipped(true, widgetID: widgetID, cardID: card.id)

        // Keep updating the model for compatibility with the main app
        try await withSharedContext { context in
            guard let cardModel = try fetchCardModel(context, id: card.id) else { return }
            cardModel.showAnswer(at: Date())
            try? context.save()
        }

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
