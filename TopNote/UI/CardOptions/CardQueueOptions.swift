//
//  CardQueueOptions.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/24/25.
//

import Foundation
import SwiftUI


struct QueueOptions: View {
    var card: Card
    var iconSize: CGFloat = 50
    
    var body: some View {
        HStack {
            if card.archived {
                AddToQueueButton(card: card, iconSize:iconSize)
                    .disabled(true)
            } else {
                
                
                if card.isEnqueue(currentDate: Date()) {
                    if card.isEssential {
                        SkipCurrentCardInQueueButton(card: card, iconSize:iconSize)
                    } else {
                        GoToNextCardInQueueButton(card: card, iconSize:iconSize)
                    }
                } else {
                    AddToQueueButton(card: card, iconSize:iconSize)
                }
            }
        }
    }
}
