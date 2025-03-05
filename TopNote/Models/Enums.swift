//
//  Enums.swift
//  TopNote
//
//  Created by Zachary Sturman on 3/4/25.
//

import Foundation

// MARK: - Card Type

enum CardType: String, CaseIterable, Identifiable {
    case flashCard = "Flash Card"
    case none = "Plain"
    
    var id: String { self.rawValue }
    
    var systemImage: String {
        switch self {
        case .flashCard:
            return "rectangle.on.rectangle.angled"
        case .none:
            return "line.3.horizontal"
        }
    }
}

// MARK: - Priority Type

enum PriorityType: String, CaseIterable, Identifiable {
    case none = "None"
    case low = "Low"
    case med = "Medium"
    case high = "High"
    
    var id: String { self.rawValue }
}

extension PriorityType {
    /// Provides a numerical value to be used for sorting priorities.
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

