//
//  PriorityType.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//



enum PriorityType: String, CaseIterable, Identifiable {
    case none = "None"
    case low = "Low"
    case med = "Medium"
    case high = "High"
    
    var id: String { self.rawValue }
    
    var displayName: String { rawValue }
    
    var iconName: String {
        switch self {
        case .high: return "flag.fill"
        case .med: return "flag"
        case .low: return "flag.slash"
        case .none: return "minus"
        }
    }
    
    var sortValue: Int {
        switch self {
        case .high: return 1
        case .med: return 2
        case .low: return 3
        case .none: return 4
        }
    }
}

