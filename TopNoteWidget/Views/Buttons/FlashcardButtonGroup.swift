//
//  FlashcardButtonGroup.swift
//  TopNoteWidget
//

import SwiftUI
import WidgetKit
import AppIntents

struct FlashcardButtonGroup: View {
    let isCardFlipped: Bool
    let skipCount: Int
    let skipEnabled: Bool
    let card: CardEntity
    let widgetID: String

    var body: some View {
        HStack(spacing: 6) {
            if isCardFlipped {
                ForEach([RatingType.hard, .good, .easy]) { rating in
                    Button(intent: SubmitFlashcardRatingTypeIntent(selectedRating: RatingType.allCases.firstIndex(of: rating) ?? 0, card: card)) {
                        WidgetCapsule(title: rating.rawValue, tint: rating.tintColor)
                    }
                    .buttonStyle(WidgetButtonStyle(color: rating.tintColor))
                }
            } else {
                Button(intent: ShowFlashcardAnswer(card: card, widgetID: widgetID)) {
                    WidgetCapsule(title: "Show answer", systemImage: "arrow.2.squarepath", tint: CardType.flashcard.tintColor)
                }
                .buttonStyle(WidgetButtonStyle(color: CardType.flashcard.tintColor))
                if skipEnabled {
                    Button(intent: SkipCardIntent(card: card)) {
                        WidgetCapsule(title: "Skip", tint: .secondary, prominent: false)
                    }
                    .buttonStyle(WidgetButtonStyle(color: .secondary))
                    .frame(maxWidth: 72)
                }
            }
        }
    }
}
