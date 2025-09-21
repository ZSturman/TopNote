//
//  CardRowSwipeLeft.swift
//  TopNote
//
//  Created by Zachary Sturman on 8/6/25.
//

import Foundation
import SwiftUI
// MARK: - Swipe Left Actions
struct CardRowSwipeLeft: View {
    @Environment(\.modelContext) private var modelContext
    var card: Card
    var showDetails: () -> Void
    var moveAction: () -> Void

    var body: some View {
        Button(role: .destructive) { modelContext.delete(card)} label: {
            Label("Delete", systemImage: "trash")
        }
        Button { showDetails() } label: {
            Label("Details", systemImage: "info.circle")
        }
        Button { moveAction() } label: {
            Label("Move", systemImage: "folder")
        }
    }
}

