//
//  CardTypePicker.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/24/25.
//

import Foundation
import SwiftUI
import WidgetKit

struct CardTypePicker: View {
    var card: Card
    @State private var selectedType: CardType

    init(card: Card) {
        self.card = card
        _selectedType = State(initialValue: card.cardType)
    }

    var body: some View {
        Picker("Card Type", selection: $selectedType) {
            Label {
                Text("Flashcard")
            } icon: {
                FlashCardIcon()
            }
            .tag(CardType.flashCard)

            Label {
                Text("Plain")
            } icon: {
                PlainCardIcon()
            }
            .tag(CardType.none)
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedType) { _, newValue in
            Task {
                do {
                    try await card.updateCardType(cardType: newValue)
                    WidgetCenter.shared.reloadAllTimelines()
                } catch {
                    print("Error updating card type: \(error)")
                }
            }
        }
    }
}
