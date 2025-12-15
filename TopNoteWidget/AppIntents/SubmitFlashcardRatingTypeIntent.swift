//
//  SubmitFlashcardRatingTypeIntent.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import WidgetKit
import AppIntents
import SwiftData

struct SubmitFlashcardRatingTypeIntent: AppIntent {
    static var title: LocalizedStringResource = "Difficulty Rating"

    @Parameter(title: "Selected Rating")
    var selectedRating: Int

    @Parameter(title: "Card")
    var card: CardEntity

    init(selectedRating: Int, card: CardEntity) {
        self.selectedRating = selectedRating
        self.card = card
    }

    init() {}

    func perform() async throws -> some IntentResult {
        try await withSharedContext { context in
            guard let cardModel = try fetchCardModel(context, id: card.id) else { return }
            let ratingCases = RatingType.allCases
            guard selectedRating >= 0, selectedRating < ratingCases.count else { return }
            cardModel.submitFlashcardRating(ratingCases[selectedRating], at: Date())
            try? context.save()
        }

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
