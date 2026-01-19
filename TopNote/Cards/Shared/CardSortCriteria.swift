//
//  CardSortCriteria.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import Foundation


enum CardSortCriteria: String, CaseIterable, Identifiable {
    case enqueuedAt
    case createdAt
    case skipCount
    case seenCount
    case content
    
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
        case .content:
            return SortDescriptor(\.content, order: ascending ? .forward : .reverse)
        }
    }
    
    /// User‐friendly label
    var localizedName: String {
        switch self {
        case .enqueuedAt: return "Queued"
        case .createdAt:  return "Created"
        case .skipCount:  return "Skips"
        case .seenCount:  return "Seen"
        case .content:    return "Content"
        }
    }
    
    /// SF Symbol for the sort criteria
    var systemImage: String {
        switch self {
        case .enqueuedAt: return "clock.arrow.circlepath"
        case .createdAt:  return "clock"
        case .skipCount:  return "forward.fill"
        case .seenCount:  return "eye"
        case .content:    return "doc.text"
        }
    }
}
