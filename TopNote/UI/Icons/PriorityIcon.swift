//
//  PriorityIcon.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/27/25.
//

import Foundation
import SwiftUI

struct PriorityIcon: View {
    var priority: PriorityType
    
    var body: some View {
        priorityIconView()
    }
    
    @ViewBuilder
    private func priorityIconView() -> some View {
        switch priority {
        case .none:
            VStack {
                Text("None")
                    .font(.caption)
                IconContainer(baseSymbol: "circle",
                            overlaySymbol: "minus",
                            overlayScale: 0.5)
                 
            }
        case .low:
            VStack {
                Text("Low")
                    .font(.caption)
                IconContainer(baseSymbol: "circle",
                            overlaySymbol: "exclamationmark",
                            overlayScale: 0.5)
                    .frame(width: 50, height: 50)
            }
        case .med:
            VStack {
                Text("Medium")
                    .font(.caption)
                IconContainer(baseSymbol: "triangle",
                            overlaySymbol: "exclamationmark",
                            overlayScale: 0.5)
                 
            }
        case .high:
            VStack {
                Text("High")
                    .font(.caption)
                IconContainer(baseSymbol: "octagon",
                            overlaySymbol: "exclamationmark",
                            overlayScale: 0.5)
                   
            }
        }
        
    }
    
    
}
