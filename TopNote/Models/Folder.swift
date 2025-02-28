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

enum FolderSelection: Identifiable, Equatable, Hashable {
    case allCards
    case folder(Folder)
    
    // For 'allCards', use a fixed UUID so that it remains constant.
    var id: UUID {
        switch self {
        case .allCards:
            return UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        case .folder(let folder):
            return folder.id
        }
    }
    
    var name: String {
        switch self {
        case .allCards:
            return "All Cards"
        case .folder(let folder):
            return folder.name
        }
    }
}
