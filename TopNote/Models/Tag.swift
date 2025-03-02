//
//  Tag.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/27/25.
//

import Foundation
import SwiftData



@Model
final class Tag {
    var id: UUID = UUID()
    var name: String = ""
    @Relationship(deleteRule: .cascade, inverse: \Card.tags)
    var cards: [Card]?
    
    var unwrappedCards: [Card] {
        cards ?? []
    }
    
    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}


enum TagSelectionState {
    case selected, deselected, neutral
}
