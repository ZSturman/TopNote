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
    @EnvironmentObject var selectedCardModel: SelectedCardModel
    var card: Card
    var showDetails: () -> Void
    var moveAction: () -> Void

    var body: some View {
        Button(role: .destructive) { 
            selectedCardModel.clearSelection()
            modelContext.delete(card)
        } label: {
            Label("Delete", systemImage: "trash")
        }
        Button { 
            selectedCardModel.clearSelection()
            showDetails() 
        } label: {
            Label("Details", systemImage: "info.circle")
        }
        Button { 
            selectedCardModel.clearSelection()
            moveAction() 
        } label: {
            Label("Move", systemImage: "folder")
        }
    }
}

