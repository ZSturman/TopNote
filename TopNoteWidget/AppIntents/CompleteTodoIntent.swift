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
    static var title: LocalizedStringResource = "Complete To-do"
    static var description = IntentDescription("Checks off a Top Note to-do. A repeating to-do comes back on schedule.")

    @Parameter(title: "To-do")
    var card: CardEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Complete \(\.$card)")
    }

    init(card: CardEntity) { self.card = card }
    init() {}

    func perform() async throws -> some IntentResult {
        try await withSharedContext { context in
            guard let cardModel = try fetchCardModel(context, id: card.id) else { return }
            cardModel.markAsComplete(at: Date())
            try? context.save()
        }

        TopNoteShared.reloadWidgets()
        return .result()
    }
}
