//
//  SkipCountChartView.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/25/25.
//

import Foundation
import SwiftUI
import Charts

// MARK: - Skip Chart View

struct SkipChartView: View {
    let skipCount: Int
    
    var body: some View {
        let data = [StatData(category: "Skip", count: skipCount)]
        
        Chart(data) { stat in
            BarMark(
                x: .value("Category", stat.category),
                y: .value("Count", stat.count)
            )
            .foregroundStyle(.red)
        }
        .padding()
    }
}

struct SkipChartView_Previews: PreviewProvider {
    static var previews: some View {
        SkipChartView(skipCount: 3)
            .previewLayout(.sizeThatFits)
    }
}
