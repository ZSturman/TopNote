//
//  RatingsChartView.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/25/25.
//

import Foundation
import SwiftUI
import Charts
// MARK: - Ratings Chart View

struct RatingsChartView: View {
    // Expect an array of rating events.
    let ratingEvents: [RatingEvent]
    
    // Aggregate rating events into counts per rating type.
    var ratingCounts: [RatingCount] {
        let grouped = Dictionary(grouping: ratingEvents, by: { $0.rating })
        return grouped.map { RatingCount(rating: $0.key, count: $0.value.count) }
            .sorted { $0.rating.rawValue < $1.rating.rawValue }
    }
    
    var body: some View {
        Chart(ratingCounts) { ratingCount in
            BarMark(
                x: .value("Rating", ratingCount.rating.rawValue),
                y: .value("Count", ratingCount.count)
            )
            .foregroundStyle(color(for: ratingCount.rating))
        }
        .padding()
    }
    
    // Assign colors for each rating type.
    func color(for rating: RatingType) -> Color {
        switch rating {
        case .easy: return .green
        case .good: return .blue
        case .hard: return .red
        }
    }
}

struct RatingsChartView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleRatingEvents = [
            RatingEvent(rating: .easy, date: Date().addingTimeInterval(-7200)),
            RatingEvent(rating: .hard, date: Date().addingTimeInterval(-3600)),
            RatingEvent(rating: .good, date: Date())
        ]
        RatingsChartView(ratingEvents: sampleRatingEvents)
            .previewLayout(.sizeThatFits)
    }
}
