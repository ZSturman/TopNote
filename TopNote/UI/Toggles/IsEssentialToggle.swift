//
//  Toggles.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/24/25.
//

import Foundation
import SwiftUI
import WidgetKit


struct IsEssentialToggle: View {
    var card: Card
    @State private var isEssential: Bool
    
    init(card: Card) {
        self.card = card
        _isEssential = State(initialValue: card.isEssential)
    }
    
    var body: some View {
        HStack {
            Label("Essential", systemImage: "exclamationmark")
                .foregroundColor(.primary)
        
            
            
            Spacer()
            Toggle("", isOn: $isEssential)
                .labelsHidden()  // Hide the default label
                .onChange(of: isEssential) {
                    Task {
                        do {
                            try await card.toggleIsEssential()
                            WidgetCenter.shared.reloadAllTimelines()
                        } catch {
                            print("Error toggling essentiality: \(error)")
                        }
                    }
                }
        }
    }
}


