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
    
    var sortValue: Int {
        switch self {
        case .high: return 1
        case .med: return 2
        case .low: return 3
        case .none: return 4
        }
    }
}

