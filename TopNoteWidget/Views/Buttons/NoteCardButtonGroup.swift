//
//  NoteCardButtonGroup.swift
//  TopNoteWidget
//

import SwiftUI
import WidgetKit
import AppIntents

struct NoteCardButtonGroup: View {
    let skipEnabled: Bool
    let card: CardEntity
    let widgetID: String

    var body: some View {
        HStack(spacing: 6) {
            Button(intent: NextCardIntent(card: card)) {
                WidgetCapsule(title: "Got it", tint: CardType.note.tintColor)
            }
            .buttonStyle(WidgetButtonStyle(color: CardType.note.tintColor))
            if skipEnabled {
                Button(intent: SkipCardIntent(card: card)) {
                    WidgetCapsule(title: "Less often", tint: CardType.note.tintColor, prominent: false)
                }
                .buttonStyle(WidgetButtonStyle(color: CardType.note.tintColor))
            }
        }
    }
}
