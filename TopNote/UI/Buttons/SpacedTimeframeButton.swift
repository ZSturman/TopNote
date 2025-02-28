//
//  SpacedTimeframeButton.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/24/25.
//

import Foundation
import SwiftUI

struct SpacedTimeframeButton: View {
    
    @Binding var showingSpacedTimeframeOptions: Bool
    
    var body: some View {
        Button(action: {showingSpacedTimeframeOptions.toggle()}, label: {
            Image(systemName: "calendar.badge.clock")
        })
        .help("Spaced repetition")
    }
}
