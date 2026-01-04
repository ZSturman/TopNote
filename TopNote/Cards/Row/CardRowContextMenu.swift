//
//  CardRowContextMenu.swift
//  TopNote
//
//  Created by Zachary Sturman on 8/6/25.
//

import Foundation
import SwiftUI
import SwiftData


// MARK: - Context Menu
struct CardRowContextMenu: View {
    @Environment(\.modelContext) private var context
    var card: Card
    var showDetails: () -> Void
    var moveAction: () -> Void
    var tagAction: () -> Void
    
    
    @Query private var folders: [Folder]
    @Query private var tags: [CardTag]
    
    private struct QuickActionButtons: View {
        let card: Card
        let context: ModelContext
        
        var body: some View {
            let isEnqueued = card.isEnqueue(currentDate: Date())
            let isArchived = card.isArchived
            let cardType = card.cardType
            let skipEnabled = card.skipEnabled

            HStack(spacing: 12) {
                switch (isArchived, isEnqueued) {
                case (true, _):
                    Button {
                        card.enqueue(at: Date())
                        try? context.save()
                    } label: {
                        Label("Enqueue", systemImage: "clock.arrow.circlepath")
                    }
                    .tint(.blue)

                    Button {
                        card.unarchive(at: Date())
                        try? context.save()
                    } label: {
                        Label("Unarchive", systemImage: "tray.and.arrow.up")
                    }
                    .tint(.green)
                case (false, true):
                    if skipEnabled {
                        Button {
                            card.skip(at: Date())
                            try? context.save()
                        } label: {
                            Label("Skip", systemImage: "forward.fill")
                        }
                        .tint(.orange)
                    }
                    
                    // Remove from queue (works for all card types)
                    Button {
                        card.next(at: Date())
                        try? context.save()
                    } label: {
                        Label("Remove", systemImage: "minus.circle")
                    }
                    .tint(.purple)
                    
                    Button {
                        card.archive(at: Date())
                        try? context.save()
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .tint(.secondary)

                    switch cardType {
                    case .flashcard:
                        Menu {
                            Button {
                                card.submitFlashcardRating(.easy, at: Date())
                                try? context.save()
                            } label: {
                                Label("Easy", systemImage: RatingType.easy.systemImage)
                            }
                            .tint(RatingType.easy.tintColor)
                            Button {
                                card.submitFlashcardRating(.good, at: Date())
                                try? context.save()
                            } label: {
                                Label("Good", systemImage: RatingType.good.systemImage)
                            }
                            .tint(RatingType.good.tintColor)
                            Button {
                                card.submitFlashcardRating(.hard, at: Date())
                                try? context.save()
                            } label: {
                                Label("Hard", systemImage: RatingType.hard.systemImage)
                            }
                            .tint(RatingType.hard.tintColor)
                        } label: {
                            Label("Rate", systemImage: card.cardType.systemImage)
                        }
                        .tint(card.cardType.tintColor)
                    case .todo:
                        Button(action: {
                            if card.isComplete {
                                card.markAsNotComplete(at: .now)
                            } else {
                                card.markAsComplete(at: .now)
                            }
                            try? context.save()
                        }) {
                            Label(card.isComplete ? "Incomplete" : "Complete", systemImage: card.isComplete ? "checkmark.circle" : "checkmark.circle.fill")
                        }
                        .tint(card.isComplete ? .orange : .green)
                    default:
                        EmptyView()
                    }
                default:
                    Button {
                        card.enqueue(at: Date())
                        try? context.save()
                    } label: {
                        Label("Enqueue", systemImage: "clock")
                    }
                    .tint(.blue)
                    Button {
                        card.archive(at: Date())
                        try? context.save()
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .tint(.secondary)
                    
                    switch cardType {
                    case .flashcard:
                        Menu {
                            Button {
                                card.submitFlashcardRating(.easy, at: Date())
                                try? context.save()
                            } label: {
                                Label("Easy", systemImage: RatingType.easy.systemImage)
                            }
                            .tint(RatingType.easy.tintColor)
                            Button {
                                card.submitFlashcardRating(.good, at: Date())
                                try? context.save()
                            } label: {
                                Label("Good", systemImage: RatingType.good.systemImage)
                            }
                            .tint(RatingType.good.tintColor)
                            Button {
                                card.submitFlashcardRating(.hard, at: Date())
                                try? context.save()
                            } label: {
                                Label("Hard", systemImage: RatingType.hard.systemImage)
                            }
                            .tint(RatingType.hard.tintColor)
                        } label: {
                            Label("Rate", systemImage: card.cardType.systemImage)
                        }
                        .tint(card.cardType.tintColor)
                    case .todo:
                        Button(action: {
                            if card.isComplete {
                                card.markAsNotComplete(at: .now)
                            } else {
                                card.markAsComplete(at: .now)
                            }
                            try? context.save()
                        }) {
                            Label(card.isComplete ? "Incomplete" : "Complete", systemImage: card.isComplete ? "checkmark.circle" : "checkmark.circle.fill")
                        }
                        .tint(card.isComplete ? .orange : .green)
                    default:
                        EmptyView()
                    }
                }
            }
        }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            QuickActionButtons(card: card, context: context)
                .padding(.horizontal, 4)
        }
        .menuActionDismissBehavior(.disabled)
        Button { showDetails() } label: {
            Label("Details", systemImage: "info.circle")
        }

        Divider()
        Menu {
            Button("New Folder...") { moveAction() }
            Divider()
            ScrollView {
                ForEach(folders.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { folder in
                    Button(action: {
                        // Move the card to the selected folder
                        card.folder = folder
                        try? context.save()
                    }) {
                        HStack {
                            Text(folder.name)
                            if card.folder == folder {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                .frame(maxHeight: 200)
            }
        } label: {
            Label("Move", systemImage: "folder")
        }

        // Tag Dropdown
        Menu {
            Button("Add Tag...") { tagAction() }
            Divider()
            ScrollView {
                ForEach(tags.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { tag in
                    Button(action: {
                        if card.unwrappedTags.contains(where: { $0.id == tag.id }) {
                            card.tags?.removeAll(where: { $0.id == tag.id })
                        } else {
                            if card.tags == nil { card.tags = [] }
                            card.tags?.append(tag)
                        }
                        try? context.save()
                    }) {
                        HStack {
                            Text(tag.name)
                            if card.unwrappedTags.contains(where: { $0.id == tag.id }) {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        } label: {
            Label("Tags", systemImage: "tag")
        }

        Button { duplicateCard(card, in: context)} label: {
            Label("Duplicate", systemImage: "doc.on.doc")
        }
        Divider()
        
        // Show different options based on deletion state
        if card.isDeleted {
            // Card is soft-deleted: show Restore and Permanently Delete
            Button {
                card.restore(at: Date())
                try? context.save()
            } label: {
                Label("Restore", systemImage: "arrow.uturn.backward")
            }
            .tint(.green)
            
            Button(role: .destructive) {
                context.delete(card)
                try? context.save()
            } label: {
                Label("Permanently Delete", systemImage: "trash.fill")
            }
            .foregroundColor(.red)
        } else {
            // Card is not deleted: show soft delete option
            Button(role: .destructive) {
                card.softDelete(at: Date())
                try? context.save()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .foregroundColor(.red)
        }
    }
}
