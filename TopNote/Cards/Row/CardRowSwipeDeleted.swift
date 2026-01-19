//
//  CardRowSwipeDeleted.swift
//  TopNote
//
//  Created by Zachary Sturman on 1/7/26.
//

import Foundation
import SwiftUI

/// Swipe actions for deleted cards - restore (leading) and permanently delete (trailing)
struct CardRowSwipeDeletedLeft: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var selectedCardModel: SelectedCardModel
    var card: Card
    @Binding var showDeleteConfirmation: Bool
    
    var body: some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            Label("Delete Forever", systemImage: "trash.fill")
        }
        .tint(.red)
    }
}

struct CardRowSwipeDeletedRight: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var selectedCardModel: SelectedCardModel
    var card: Card
    
    var body: some View {
        Button {
            selectedCardModel.clearSelection()
            card.restore(at: Date())
            try? modelContext.save()
        } label: {
            Label("Restore", systemImage: "arrow.uturn.backward")
        }
        .tint(.green)
    }
}
