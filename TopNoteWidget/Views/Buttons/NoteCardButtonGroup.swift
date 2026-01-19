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
                NextButtonUI()
            }
            .frame(width: buttonSize, height: buttonSize)
            .buttonStyle(WidgetButtonStyle(color: .blue))

            Spacer()

            RecurringMessage(card: card)

            Spacer()


            if skipEnabled {
                Button(intent: SkipCardIntent(card: card)) {
                    SkipButtonUI()
                }
                .frame(width: buttonSize, height: buttonSize)
                .buttonStyle(WidgetButtonStyle(color: .orange))
            }
        }
        .padding(6)
    }
}
