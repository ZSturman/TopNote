//
//  SkipCountChartView.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/25/25.
//

import Foundation
import SwiftUI
import Charts


// MARK: - Skip+Seen Chart View

struct SkipSeenChartView: View {
    let skipCount: Int
    let seenCount: Int
    
    var body: some View {
        // Prepare data for the two categories.
        let data = [
            StatData(category: "Skip", count: skipCount),
            StatData(category: "Seen", count: seenCount)
        ]
        
        Chart(data) { stat in
            BarMark(
                x: .value("Category", stat.category),
                y: .value("Count", stat.count)
            )
            .foregroundStyle(by: .value("Category", stat.category))
        }
        .chartForegroundStyleScale([
            "Skip": .red,
            "Seen": .blue
        ])
        .padding()
    }
}

// MARK: - Previews

struct SkipSeenChartView_Previews: PreviewProvider {
    static var previews: some View {
        SkipSeenChartView(skipCount: 3, seenCount: 10)
            .previewLayout(.sizeThatFits)
    }
}
