//
//  CardType.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import AppIntents
import SwiftUI


enum CardType: String, CaseIterable, Identifiable, AppEnum  {
    case flashcard = "Flashcard"
    case todo = "To-do"
    case note = "Note"
    
    var id: String { self.rawValue }
    
    var systemImage: String {
        switch self {
        case .flashcard:
            return "rectangle.on.rectangle.angled"
        case .note:
            return "doc.text"
        case .todo:
            return "checklist"
        }
    }
    

    /// Accent color for each card type
    var tintColor: Color {
        switch self {
        case .todo:      return .green
        case .flashcard: return .blue
        case .note:      return .yellow
        }
    }
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Card Type"
    }

    static var caseDisplayRepresentations: [CardType: DisplayRepresentation] {
        [
            .flashcard: "Flashcard",
            .todo: "To-do",
            .note: "Note",
        ]
    }
}
