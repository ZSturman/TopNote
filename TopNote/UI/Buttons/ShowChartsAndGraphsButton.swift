//
//  ShowChartsAndGraphsButton.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/24/25.
//

import Foundation
import SwiftUI

struct ShowChartsAndGraphsButton: View {
    
    @Binding var showingCardStats: Bool
    
    var body: some View {
        Button(action: {showingCardStats.toggle()}, label: {
            Image(systemName: "chart.bar")
        })
        .help("Card stats")
    }
}
