//
//  RatingModels.swift
//  TopNote
//
//  Created by Zachary Sturman on 3/4/25.
//

import Foundation

// MARK: - StatData

struct StatData: Identifiable {
    var id = UUID()
    var category: String
    var count: Int
}

// MARK: - RatingEvent

struct RatingEvent: Identifiable {
    let id = UUID()
    let rating: RatingType
    let date: Date
}

// MARK: - RatingCount

struct RatingCount: Identifiable {
    var id: String { rating.rawValue }
    let rating: RatingType
    let count: Int
}
