//
//  Enums.swift
//  TopNote
//
//  Created by Zachary Sturman on 3/4/25.
//

import Foundation
import SwiftUI
import WidgetKit
import AppIntents

// MARK: - Card Type

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
    
    var iconName: String {
        switch self {
        case .todo:      return "checkmark.circle"
        case .flashcard: return "questionmark.circle"
        case .note:      return "note.text"
        // add your other types here
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

// MARK: - Priority Type

enum PriorityType: String, CaseIterable, Identifiable {
    case none = "None"
    case low = "Low"
    case med = "Medium"
    case high = "High"
    
    var id: String { self.rawValue }
    
    var sortValue: Int {
        switch self {
        case .high: return 1
        case .med: return 2
        case .low: return 3
        case .none: return 4
        }
    }
}


// MARK: - Rating Type

enum RatingType: String, CaseIterable, Identifiable, Codable {
    case easy = "Easy"
    case good = "Good"
    case hard = "Hard"
    
    var id: String { self.rawValue }
    
    var systemImage: String {
        switch self {
        case .easy:
            return "trophy"
        case .good:
            return "hand.thumbsup.fill"
        case .hard:
            return "exclamationmark.questionmark"
        }
    }
    
    var tintColor: Color {
        switch self {
        case .easy:
            return .green
        case .good:
            return .blue
        case .hard:
            return .red
        }
    }
    
    var description: String {
        switch self {
        case .easy: return "You found this card easy to answer."
        case .good: return "You answered this card correctly with some effort."
        case .hard: return "You struggled to answer this card. Review it again soon."
        }
    }
    
}

enum RepeatInterval: String, CaseIterable, Codable {
    
    case daily        = "Daily"
    case every3days = "3 Days"
    case every5Days   = "5 Days"
    case weekly       = "Weekly"
    case every10Days = "10 Days"
    case every2Weeks = "2 Weeks"
    case every20Days = "20 Days"
    case monthly      = "Monthly"
    case everyMonthAndHalf = "45 Days"
    case every2Months = "2 Months"
    case every3Months = "3 Months"
    case every4Months = "4 Months"
    case every6Months = "6 Months"
    case every9Months = "9 Months"
    case yearly       = "Yearly"
    
    /// Fixed interval in hours; `nil` for `.dynamic`
    var hours: Int? {
        switch self {
        case .daily:        return 24
        case .every3days:   return 72
        case .every5Days:   return 120
        case .weekly:       return 168
        case .every10Days:  return 240
        case .every2Weeks:  return 336
        case .every20Days:  return 480
        case .monthly:      return 720
        case .everyMonthAndHalf: return 1080 // 45 days
        case .every2Months: return 1440 // 2 months
        case .every3Months: return 2160 // 3 months
        case .every4Months: return 2880 // 4 months
        case .every6Months: return 4320 // 6 months
        case .every9Months: return 6480 // 9 months
        case .yearly:       return 8760 // 1 year
        }
    }
    

    
    init(hours: Int) {
        if let match = Self.allCases.first(where: { $0.hours == hours }) {
            self = match
        } else {
            // Default to daily if no match found
            self = .daily
        }
    }
}

enum RepeatPolicy: String, CaseIterable, Codable {
    case aggressive = "Aggressive"
    case mild       = "Mild"
    case none       = "None"
    
    /// A short, friendly description of how the card's interval will change based on the rating and repeat policy.
    func shortDescription(for rating: RatingType?) -> String {
        let effectiveRating = rating ?? .hard
        switch self {
        case .aggressive:
            switch effectiveRating {
            case .hard:
                return "Much sooner"
            case .easy, .good:
                return "Much later"
            }
        case .mild:
            switch effectiveRating {
            case .hard:
                return "A little sooner"
            case .easy, .good:
                return "A little later"
            }
        case .none:
            return "No change"
        }
    }
    
    var skipMultiplier: Double {
        switch self {
        case .aggressive: return 0.5
        case .mild:       return 0.75
        case .none:       return 1.0
        }
    }
    
    var easyMultiplier: Double {
        switch self {
        case .aggressive: return 1.5
        case .mild:       return 1.25
        case .none:       return 1.0
        }
    }

    var goodMultiplier: Double {
        switch self {
        case .aggressive: return 1.25
        case .mild:       return 1.15
        case .none:       return 1.0
        }
    }
    
    var hardMultiplier: Double {
        switch self {
        case .aggressive: return 0.5
        case .mild:       return 0.75
        case .none:       return 1.0
        }
    }
    
    var skipAndHardDescription: String {
        switch self {
        case .aggressive:
            return "Aggressive scheduling makes cards appear more frequently based on your performance."
        case .mild:
            return "Mild scheduling adjusts the frequency of cards moderately based on your performance."
        case .none:
            return "No scheduling adjustments will be made based on your performance."
        }
    }
    
    var goodAndEasyDescription: String {
        switch self {
        case .aggressive:
            return "Aggressive scheduling makes cards appear less frequently based on your performance."
        case .mild:
            return "Mild scheduling adjusts the frequency of cards moderately based on your performance."
        case .none:
            return "No scheduling adjustments will be made based on your performance."
        }
    }
    
    

        
            
    
    
    var skipPolicyDescription: String {
        return "Skips reduce the current repeat interval by a factor of \(String(format: "%.2f", skipMultiplier)). This means the card will be shown more frequently."
    }
    
    var easyPolicyDescription: String {
        return "Easy ratings decrease the current repeat interval by a factor of \(String(format: "%.2f", easyMultiplier)) meaning the card will be shown less frequently."
    }
    
    var goodPolicyDescription: String {
        return "Good ratings decrease the current repeat interval by a factor of \(String(format: "%.2f", goodMultiplier)) meaning the card will be shown less frequently."
    }
    
    var hardPolicyDescription: String {
        return "Hard ratings increase the current repeat interval by a factor of \(String(format: "%.2f", hardMultiplier)) meaning the card will be shown more frequently."
    }
}



// MARK: - Folder Selection

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



enum TagSelectionState {
    case selected, deselected, neutral
}


enum CardSortCriteria: String, CaseIterable, Identifiable {
    case enqueuedAt
    case createdAt
    case skipCount
    case seenCount
    
    var id: String { rawValue }
    
    /// Convert to a SwiftData SortDescriptor
    func sortDescriptor(ascending: Bool) -> SortDescriptor<Card> {
        switch self {
        case .enqueuedAt:
            return SortDescriptor(\.nextTimeInQueue, order: ascending ? .forward : .reverse)
        case .createdAt:
            return SortDescriptor(\.createdAt, order: ascending ? .forward : .reverse)

        case .skipCount:
            return SortDescriptor(\.skipCount, order: ascending ? .forward : .reverse)
        case .seenCount:
            return SortDescriptor(\.seenCount, order: ascending ? .forward : .reverse)
        }
    }
    
    /// User‐friendly label
    var localizedName: String {
        switch self {
        case .enqueuedAt: return "Enqueued"
        case .createdAt:  return "Created"
        case .skipCount:  return "Skips"
        case .seenCount:  return "Seen"
        }
    }
}

enum CardFilterOption: String, CaseIterable, Identifiable {
    
    // CARD TYPES
    case todo
    case flashcard
    case note
    
    // CARD STATES
    case enqueue
    case upcoming
    case archived
    
    var id: String { rawValue }
    
    static var typeFilters: [CardFilterOption] {
           [.todo, .flashcard, .note]
       }
       static var statusFilters: [CardFilterOption] {
           [.enqueue, .upcoming, .archived]
       }
    
    var localizedName: String {
        switch self {
        case .todo:      return "To-Do"
        case .flashcard: return "Flashcards"
        case .note:      return "Notes"
        case .enqueue:   return "Enqueued"
        case .upcoming:  return "Upcoming"
        case .archived:  return "Archived"
        }
    }
}

