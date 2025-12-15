//
//  TodoCardButtonGroup.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import SwiftUI
import WidgetKit
import AppIntents

struct TodoCardButtonGroup: View {
    let skipEnabled: Bool
    let card: CardEntity
    let widgetID: String
    let showTextToggle: Bool

    init(skipEnabled: Bool, card: CardEntity, widgetID: String, showTextToggle: Bool = false) {
        self.skipEnabled = skipEnabled
        self.card = card
        self.widgetID = widgetID
        self.showTextToggle = showTextToggle
    }

    var body: some View {
        let isTextHidden = WidgetStateManager.shared.isTextHidden(widgetID: widgetID, cardID: card.id)

        HStack {
            Button(intent: CompleteTodoIntent(card: card)) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.85))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    Image(systemName: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .frame(width: buttonSize, height: buttonSize)
            .buttonStyle(WidgetButtonStyle(color: .green))

            Spacer()

            RecurringMessage(card: card)

            Spacer()

            if showTextToggle {
                Button(intent: ToggleWidgetTextIntent(card: card, widgetID: widgetID)) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.85))
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                        Image(systemName: "textformat.characters")
                            .font(.caption)
                            .foregroundColor(.white)

                        if !isTextHidden {
                            Capsule()
                                .fill(Color.white)
                                .frame(width: 22, height: 2)
                                .rotationEffect(.degrees(33))
                                .shadow(color: .gray.opacity(0.1), radius: 3, x: 0, y: 1)
                        }
                    }
                }
                .frame(width: buttonSize, height: buttonSize)
                .buttonStyle(WidgetButtonStyle(color: .gray))
                .accessibilityLabel(Text(isTextHidden ? "Show text" : "Hide text"))
            }

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
        }
        .padding(6)
    }
}
