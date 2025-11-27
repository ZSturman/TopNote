//
//  RepeatPolicy.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//


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
    
    /// Skip description specifically for notes (with reversed aggression semantics)
    var skipDescriptionForNote: String {
        switch self {
        case .aggressive:
            return "A lot later"
        case .mild:
            return "A little later"
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
