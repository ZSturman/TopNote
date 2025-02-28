//
//  CardArchiveOptions.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/24/25.
//

import Foundation
import SwiftUI

struct ArchiveOptions: View {
    var card: Card
    var iconSize: CGFloat = 50
    
    var body: some View {
        if card.archived {
            RemoveFromArchiveButton(card: card, iconSize: iconSize)
        } else {
            AddToArchiveButton(card: card, iconSize:iconSize)
        }
    }
}
