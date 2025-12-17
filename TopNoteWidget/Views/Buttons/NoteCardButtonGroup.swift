//
//  NoteCardButtonGroup.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import SwiftUI
import WidgetKit
import AppIntents

struct NoteCardButtonGroup: View {
    let skipEnabled: Bool
    let card: CardEntity
    let widgetID: String

    init(skipEnabled: Bool, card: CardEntity, widgetID: String) {
        self.skipEnabled = skipEnabled
        self.card = card
        self.widgetID = widgetID
    }

    var body: some View {

        HStack {
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
            }
        }
        .padding(6)
    }
}
