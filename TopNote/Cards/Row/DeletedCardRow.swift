//
//  DeletedCardRow.swift
//  TopNote
//
//  Created by Zachary Sturman on 1/3/26.
//

import Foundation
import SwiftUI

/// A row view for displaying soft-deleted cards, matching regular card row styling.
/// Swipe right to restore, swipe left to permanently delete.
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
    
    private var daysUntilPermanentDeletion: Int? {
        guard let deletedAt = card.deletedAt else { return nil }
        let thirtyDaysLater = Calendar.current.date(byAdding: .day, value: 30, to: deletedAt) ?? deletedAt
        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: thirtyDaysLater).day ?? 0
        return max(0, daysRemaining)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header with folder and deletion info
            HStack(spacing: 6) {
                if let folder = card.folder {
                    HStack(spacing: 3) {
                        Image(systemName: "folder.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(folder.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(deletionDateText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let days = daysUntilPermanentDeletion {
                        Text("\(days) day\(days == 1 ? "" : "s") left")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Content
            HStack(spacing: 6) {
                Image(systemName: card.cardType.systemImage)
                    .font(.caption)
                    .foregroundColor(card.cardType.tintColor)
                
                Text(card.content.isEmpty ? "Untitled" : card.content)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.clear)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .contentShape(Rectangle())
        // Swipe right to restore
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                onRestore()
            } label: {
                Label("Restore", systemImage: "arrow.uturn.backward")
            }
            .tint(.green)
        }
        // Swipe left to permanently delete
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
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
