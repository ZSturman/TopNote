//
//  AddCardToArchiveButton.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/24/25.
//

import Foundation
import SwiftUI

struct AddToArchiveButton: View {
    var card: Card
    var iconSize: CGFloat = 50

    var body: some View {
        Button(action: {
            Task {
                do {
                    try await card.removeFromQueue(at: Date(), isSkip: false, toArchive: true)
                } catch {
                    print("Error adding card to archive: \(error)")
                }
            }
        }) {
            ResponsiveView { width in
                HStack {
                    Spacer()
                    ArchiveIcon()
                        .frame(width: iconSize, height: iconSize)
                    if width > 120 {
                        Text("Archive")
                    }
                    Spacer()
                }
            }
        }
        .help("Add to archive")
    }
}
