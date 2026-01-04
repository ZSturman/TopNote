//
//  CardRowSwipeRight.swift
//  TopNote
//
//  Created by Zachary Sturman on 8/6/25.
//

import Foundation
import SwiftUI

// MARK: - Swipe Right Actions
struct CardRowSwipeRight: View {
    var card: Card
    @Environment(\.modelContext) private var context
    @EnvironmentObject var selectedCardModel: SelectedCardModel
    
    var body: some View {
        let isEnqueued = card.isEnqueue(currentDate: Date())
        let isArchived = card.isArchived
        let cardType = card.cardType
        let skipEnabled = card.skipEnabled
        
        VStack {
            switch (isArchived, isEnqueued) {
            case (true, _):
                // Archived
                Button {
                    selectedCardModel.clearSelection()
                    card.enqueue(at: Date())
                } label: {
                    Label("Enqueue", systemImage: "clock.arrow.circlepath")
                }
                .tint(.blue)

                Button {
                    selectedCardModel.clearSelection()
                    card.unarchive(at: Date())
                } label: {
                    Label("Unarchive", systemImage: "tray.and.arrow.up")
                }
                .tint(.green)
            case (false, true):
                // Enqueued
                if skipEnabled {
                    Button {
                        selectedCardModel.clearSelection()
                        card.skip(at: Date())
                    } label: {
                        Label("Skip", systemImage: "forward.fill")
                    }
                    .tint(.orange)
                }
                
                // Remove from queue (works for all card types)
                Button {
                    selectedCardModel.clearSelection()
                    card.next(at: Date())
                } label: {
                    Label("Remove", systemImage: "minus.circle")
                }
                .tint(.purple)
                
                Button {
                    selectedCardModel.clearSelection()
                    card.archive(at: Date())
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }
                .tint(.secondary)

                // Card type specific actions
                switch cardType {
                case .flashcard:
                    Menu {
                        Button {
                            selectedCardModel.clearSelection()
                            card.submitFlashcardRating(.easy, at: Date())
                        } label: {
                            Label("Easy", systemImage: RatingType.easy.systemImage)
                        }
                        .tint(RatingType.easy.tintColor)
                        Button {
                            selectedCardModel.clearSelection()
                            card.submitFlashcardRating(.good, at: Date())
                        } label: {
                            Label("Good", systemImage: RatingType.good.systemImage)
                        }
                        .tint(RatingType.good.tintColor)
                        Button {
                            selectedCardModel.clearSelection()
                            card.submitFlashcardRating(.hard, at: Date())
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
                        selectedCardModel.clearSelection()
                        if card.isComplete {
                            card.markAsNotComplete(at: .now)
                        } else {
                            card.markAsComplete(at: .now)
                        }
                    }) {
                        Label(card.isComplete ? "Incomplete" : "Complete", systemImage: card.isComplete ? "checkmark.circle" : "checkmark.circle.fill")
            
                    }
                    .tint(card.isComplete ? .orange : .green)
                
                default:
                    EmptyView()
                }
            default:
                // Neither enqueued nor archived
                Button {
                    selectedCardModel.clearSelection()
                    card.enqueue(at: Date())
                } label: {
                    Label("Enqueue", systemImage: "clock")
                }
                .tint(.blue)
                Button {
                    selectedCardModel.clearSelection()
                    card.archive(at: Date())
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }
                .tint(.secondary)
            }
        }
    }
    
}

