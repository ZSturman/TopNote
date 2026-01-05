//
//  DeletedCardRow.swift
//  TopNote
//
//  Created by Zachary Sturman on 1/3/26.
//

import Foundation
import SwiftUI

/// A specialized row view for displaying soft-deleted cards with restore/delete actions.
struct DeletedCardRow: View {
    let card: Card
    let folders: [Folder]
    let onRestore: () -> Void
    let onPermanentDelete: () -> Void
    
    @State private var showDeleteConfirmation = false
    
    private var deletionDateText: String {
        guard let deletedAt = card.deletedAt else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Deleted \(formatter.localizedString(for: deletedAt, relativeTo: Date()))"
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: card.cardType.systemImage)
                        .foregroundColor(card.cardType.tintColor)
                        .font(.caption)
                    
                    Text(card.content.isEmpty ? "Untitled" : card.content)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                }
                
                Text(deletionDateText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Quick action buttons
            HStack(spacing: 12) {
                Button {
                    onRestore()
                } label: {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Restore card")
                
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Permanently delete card")
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .swipeActions(edge: .leading) {
            Button {
                onRestore()
            } label: {
                Label("Restore", systemImage: "arrow.uturn.backward")
            }
            .tint(.green)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
        }
        .confirmationDialog(
            "Permanently Delete?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Forever", role: .destructive) {
                onPermanentDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. The card will be permanently removed.")
        }
    }
}
