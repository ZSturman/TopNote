//
//  TodoCardButtonGroup.swift
//  TopNoteWidget
//

import SwiftUI
import WidgetKit
import AppIntents

struct TodoCardButtonGroup: View {
    let skipEnabled: Bool
    let card: CardEntity
    let widgetID: String

    var body: some View {
        HStack(spacing: 6) {
            Button(intent: CompleteTodoIntent(card: card)) {
                WidgetCapsule(title: "Done", systemImage: "checkmark", tint: CardType.todo.tintColor)
            }
            .buttonStyle(WidgetButtonStyle(color: CardType.todo.tintColor))
            Button(intent: SkipCardIntent(card: card)) {
                WidgetCapsule(title: "Later", tint: .orange, prominent: false)
            }
            .buttonStyle(WidgetButtonStyle(color: .orange))
        }
    }
}
