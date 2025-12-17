//
//  FlashcardButtonGroup.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
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

    init(
        isCardFlipped: Bool,
        skipCount: Int,
        skipEnabled: Bool,
        card: CardEntity,
        widgetID: String,
    ) {
        self.isCardFlipped = isCardFlipped
        self.skipCount = skipCount
        self.skipEnabled = skipEnabled
        self.card = card
        self.widgetID = widgetID
    }

    var body: some View {

        if isCardFlipped {
            HStack(spacing: 12) {
                ratingButton(ratingType: .easy, card: card)
                ratingButton(ratingType: .good, card: card)
                ratingButton(ratingType: .hard, card: card)

                Spacer()

                RecurringMessage(card: card)

                Spacer()

                skipOrNextButton()
            }
            .padding(6)
            .transition(.opacity.combined(with: .scale))
        } else {
            HStack(spacing: 12) {
                Button(intent: ShowFlashcardAnswer(card: card, widgetID: widgetID)) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.85))
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        Image(systemName: "rectangle.2.swap")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                .frame(width: buttonSize, height: buttonSize)
                .buttonStyle(WidgetButtonStyle(color: .purple))

                Spacer()

                RecurringMessage(card: card)

                Spacer()

                if skipEnabled {
                    Button(intent: SkipCardIntent(card: card)) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.85))
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            Image(systemName: "arrow.trianglehead.counterclockwise.rotate.90")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: buttonSize, height: buttonSize)
                    .buttonStyle(WidgetButtonStyle(color: .orange))
                } else {
                    Button(intent: NextCardIntent(card: card)) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.85))
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            Image(systemName: "checkmark.rectangle.stack")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: buttonSize, height: buttonSize)
                    .buttonStyle(WidgetButtonStyle(color: .blue))
                }
            }
            .padding(6)
            .transition(.opacity.combined(with: .scale))
        }
    }

    private func ratingButton(ratingType: RatingType, card: CardEntity) -> some View {
        Button(
            intent: SubmitFlashcardRatingTypeIntent(
                selectedRating: RatingType.allCases.firstIndex(of: ratingType) ?? 0,
                card: card
            )
        ) {
            ZStack {
                Circle()
                    .fill(color(for: ratingType).opacity(0.85))
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                Image(systemName: ratingType.systemImage)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .frame(width: buttonSize, height: buttonSize)
        .buttonStyle(WidgetButtonStyle(color: color(for: ratingType)))
    }

    private func color(for ratingType: RatingType) -> Color {
        switch ratingType {
        case .easy:
            return .green
        case .good:
            return .blue
        case .hard:
            return .red
        }
    }

    private func skipOrNextButton() -> some View {
        if skipEnabled {
            return Button(intent: SkipCardIntent(card: card)) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.85))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    Image(systemName: "forward.frame")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .frame(width: buttonSize, height: buttonSize)
            .buttonStyle(WidgetButtonStyle(color: .orange))
        } else {
            return Button(intent: NextCardIntent(card: card)) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.85))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    Image(systemName: "checkmark.rectangle.stack")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .frame(width: buttonSize, height: buttonSize)
            .buttonStyle(WidgetButtonStyle(color: .blue))
        }
    }
}
