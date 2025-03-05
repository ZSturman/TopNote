//
//  AddToQueueButton.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/24/25.
//

import Foundation
import SwiftData
import SwiftUI

struct AddToQueueButton: View {
    var card: Card
    var iconSize: CGFloat = 50
    
        
    var body: some View {
        Button(action: {
            Task {
                do {
                    try await card.addCardToQueue(currentDate: Date())
                } catch {
                    print("Error removing card from archive: \(error)")
                }
            }
        }) {
            ResponsiveView { width in
                HStack {
                    Spacer()
                    EnqueueIcon()
                        .frame(width: iconSize, height: iconSize)
                    if width > 120 {
                        Text("Enqueue")
                    }
                    Spacer()
                }
            }
        }
        .help("Add to queue")
    }
}


struct EnqueueButton: View {
    var card: Card
    
    var body: some View {
        Button(action: {
            Task {
                do {
                    try await card.addCardToQueue(currentDate: Date())
                } catch {
                    print("Error removing card from archive: \(error)")
                }
            }
        }) {
            Label("Enqueue", systemImage: "rectangle.stack")
        }
    }
}
