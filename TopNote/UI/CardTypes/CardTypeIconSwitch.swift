//
//  CardTypeIconSwitch.swift
//  TopNote
//
//  Created by Zachary Sturman on 3/1/25.
//

import Foundation
import SwiftUI

struct SelectedCardType: View {
    var cardType: CardType
    
    var body: some View {
        selectedCardTypeIcon()
    }
    
    @ViewBuilder
    private func selectedCardTypeIcon() -> some View {
        switch cardType {
        case .flashCard:
            Image(systemName: "rectangle.on.rectangle.angled")
                .font(.caption)
        case .none:
            Image(systemName: "list.dash.header.rectangle")
                .font(.caption)
        }
    }
}


