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
            case .todo:
                return Color(uiColor: UIColor { traits in
                    traits.userInterfaceStyle == .dark
                        ? UIColor.systemGreen
                        : UIColor(red: 0.10, green: 0.55, blue: 0.25, alpha: 1.0) // darker green
                })

            case .flashcard:
                return Color(uiColor: UIColor { traits in
                    traits.userInterfaceStyle == .dark
                        ? UIColor.systemBlue
                        : UIColor(red: 0.10, green: 0.35, blue: 0.75, alpha: 1.0) // deeper blue
                })

            case .note:
                return Color(uiColor: UIColor { traits in
                    traits.userInterfaceStyle == .dark
                        ? UIColor.systemYellow
                        : UIColor(red: 0.75, green: 0.45, blue: 0.05, alpha: 1.0) // amber/orange
                })
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
