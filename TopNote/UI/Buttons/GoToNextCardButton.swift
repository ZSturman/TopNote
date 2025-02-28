//
//  GoToNextCardButton.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/24/25.
//

import Foundation
import SwiftUI

struct GoToNextCardInQueueButton: View {
    var card: Card
    var iconSize: CGFloat = 50

    
    var removeBorder: Bool {
        if iconSize < 40 {
            return true
        }
        return false
    }

    
    var body: some View {
        Button(action: {
            Task {
                do {
                    try await card.removeFromQueue(at: Date(), isSkip: false, toArchive: false)
                } catch {
                    print("Error removing card from queue: \(error)")
                }
            }
        }) {
            ResponsiveView { width in
                HStack {
                    Spacer()
                    NextIcon(removeBorder:removeBorder)
                        .frame(width: iconSize, height: iconSize)
                    if width > 120 {
                        Text("Next")
                    }
                    Spacer()
                }
            }
        }
        .help("Next")
    }
}

