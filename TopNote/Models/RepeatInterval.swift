//
//  RepeatInterval.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//


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

