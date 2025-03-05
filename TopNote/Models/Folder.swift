//
//  FolderModel.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/22/25.
//

import Foundation
import SwiftData

@Model
final class Folder {
    var id: UUID = UUID()
    var name: String = ""
    @Relationship(deleteRule: .cascade)
    var cards: [Card]?
    
    var unwrappedCards: [Card] {
        cards ?? []
    }
    
    
    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}
