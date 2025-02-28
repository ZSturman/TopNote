//
//  RemoveCardFromArchiveButton.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/24/25.
//

import Foundation
import SwiftUI

struct RemoveFromArchiveButton: View {
    var card: Card
    var iconSize: CGFloat = 50

    var body: some View {
        Button(action: {
            Task {
                do {
                    try await card.removeCardFromArchive()
                } catch {
                    print("Error removing card from archive: \(error)")
                }
            }
        }) {
            ResponsiveView { width in
                HStack {
                    Spacer()
                    RemoveFromArchiveIcon()
                        .frame(width: iconSize, height: iconSize)
                    
                    if width > 120 {
                        Text("Unarchive")
                    }
                    Spacer()
                }
            }
        }
        .help("Unarchive")
    }
}
