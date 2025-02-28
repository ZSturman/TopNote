//
//  DynamicToggleView.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/23/25.
//

import Foundation
import SwiftUI
import WidgetKit


struct IsDynamicToggle: View {
    var card: Card
    
    @State private var isDynamic: Bool
    
    init(card: Card) {
        self.card = card
        _isDynamic = State(initialValue: card.dynamicTimeframe)
    }
    
    var body: some View {
        HStack {
            Label("Dynamic", systemImage: "bolt.fill")
                .foregroundColor(.primary)
            
            
            
            Spacer()
            Toggle("", isOn: $isDynamic)
                .labelsHidden()  // Hide the default label
                .onChange(of: isDynamic) {
                    Task {
                        do {
                            try await card.toggleIsDynamic()
                            WidgetCenter.shared.reloadAllTimelines()
                        } catch {
                            print("Error toggling dynamic: \(error)")
                        }
                    }
                }
        }
    }
}


