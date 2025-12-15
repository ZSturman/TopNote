//
//  CompleteTodoIntent.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import WidgetKit
import AppIntents
import SwiftData

struct CompleteTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Todo"

    @Parameter(title: "Card")
    var card: CardEntity

    init(card: CardEntity) { self.card = card }
    init() {}

    func perform() async throws -> some IntentResult {
        try await withSharedContext { context in
            guard let cardModel = try fetchCardModel(context, id: card.id) else { return }
            cardModel.markAsComplete(at: Date())
            try? context.save()
        }

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
