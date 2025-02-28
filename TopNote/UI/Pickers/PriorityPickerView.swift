//
//  PriorityPickerView.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/23/25.
//

import Foundation
import SwiftUI
import WidgetKit

struct PriorityPickerView: View {
    var card: Card
    
    @State private var priority: PriorityType
    
    init(card: Card) {
        self.card = card
        _priority = State(initialValue: card.priority)
    }
    
    var body: some View {
        
        
        Picker("Priority", selection: $priority) {
            ForEach(PriorityType.allCases) { priority in
                Text(priority.rawValue).tag(priority)
            }
        }
        .onChange(of: priority) {
            
            Task {
                do {
                    try await card.updatePriorityValue(priority: priority)
                    WidgetCenter.shared.reloadAllTimelines()
                } catch {
                    print("Error updating card priority: \(error)")
                }
                
                
                
            }
        }
        
    }
}
