//
//  SeenCountChartView.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/25/25.
//

import Foundation
import SwiftUI
import Charts


// MARK: - Seen Chart View

struct SeenChartView: View {
    let seenCount: Int
    
    var body: some View {
        let data = [StatData(category: "Seen", count: seenCount)]
        
        Chart(data) { stat in
            BarMark(
                x: .value("Category", stat.category),
                y: .value("Count", stat.count)
            )
            .foregroundStyle(.blue)
        }
        .padding()
    }
}

struct SeenChartView_Previews: PreviewProvider {
    static var previews: some View {
        SeenChartView(seenCount: 10)
            .previewLayout(.sizeThatFits)
    }
}

