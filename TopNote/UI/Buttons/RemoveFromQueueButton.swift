//
//  RemoveFromQueueButton.swift
//  TopNote
//
//  Created by Zachary Sturman on 3/2/25.
//

import Foundation
import SwiftUI
import SwiftData

struct RemoveFromQueueButton: View {
    var card: Card
    
    var body: some View {
        Button {
            Task {
                do {
                    if card.isEssential {
                        try await card.removeFromQueue(at: Date(), isSkip: true)
                    } else {
                        try await card.removeFromQueue(at: Date(), isSkip: false)
                    }
                } catch {
                    print("Error removing card from archive: \(error)")
                }
            }
        } label: {
            if card.isEssential {
                Label("Skip", systemImage: "arrow.trianglehead.counterclockwise.rotate.90")
            } else {
                Label("Next", systemImage: "checkmark.rectangle.stack")
            }
        }
    }
}
