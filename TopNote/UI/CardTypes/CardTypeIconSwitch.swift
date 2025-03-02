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
            FlashCardIcon()
                .frame(width: 30, height: 30)
        case .none:
            PlainCardIcon()
                .frame(width: 30, height: 30)
        }
    }
}


