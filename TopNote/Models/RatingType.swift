//
//  RatingType.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import SwiftUI


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

