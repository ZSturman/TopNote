//
//  CardRow.swift
//  TopNote
//
//  Created by Zachary Sturman on 7/28/25.
//

import SwiftUI
import SwiftData
import WidgetKit
import TipKit

struct CardRow: View {
    @EnvironmentObject var selectedCardModel: SelectedCardModel
    @Environment(\.modelContext) var modelContext

    var card: Card
    var folders: [Folder]  // Passed from parent to avoid per-row queries
    var onCommit: (() -> Void)? = nil
    var onPriorityChanged: ((UUID) -> Void)? = nil
    var lastDeselectedCardID: UUID? = nil

    // REMOVED: @Query var tags: [CardTag] - this was creating 700+ separate queries
    // REMOVED: @Query var folders: [Folder] - now passed as parameter

    // Selection / editing
    @State var showingFlashcardAnswer = false
    @State var draftContent: String = ""
    @State var draftAnswer: String = ""
    @State var saveTask: Task<Void, Never>? = nil

    @State var activeSheet: CardRowSheet? = nil

    @FocusState var isContentEditorFocused: Bool
    @FocusState var isAnswerEditorFocused: Bool

    // Info dialogs
    @State var showingLongInfo = false
    @State var showingRatingsPolicyInfo = false
    @State var showingSkipInfo = false
    @State var showingEnqueueIntervalInfo = false

    enum CardRowSheet: Identifiable {
        case details, move, tags
        var id: Int { self.hashValue }
    }

    var isSelected: Bool {
        selectedCardModel.selectedCard?.id == card.id
    }
    
    private func deleteIfEmptyAndNotSelected() {
        // DISABLED: Auto-delete was causing issues - cards being deleted unexpectedly
        // This function is no longer called but kept for reference
    }

    var body: some View {
        VStack(spacing: 0) {
            CardRowMainContent(
                card: card,
                isSelected: isSelected,
                draftContent: $draftContent,
                draftAnswer: $draftAnswer,
                showingFlashcardAnswer: $showingFlashcardAnswer,
                isContentEditorFocused: $isContentEditorFocused,
                folders: folders,
                onPriorityChanged: onPriorityChanged,
                moveAction: { activeSheet = .move }
                // MARK: - IMAGE DISABLED
                // selectedContentPhoto: $selectedContentPhoto,
                // selectedAnswerPhoto: $selectedAnswerPhoto
            )
            CardRowFooter(
                card: card,
                showingLongInfo: $showingLongInfo,
                showingRatingsPolicyInfo: $showingRatingsPolicyInfo,
                showingSkipInfo: $showingSkipInfo
            )
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    isSelected ? card.cardType.tintColor.opacity(0.12) : 
                    (lastDeselectedCardID == card.id ? card.cardType.tintColor.opacity(0.12) : Color.clear)
                )
                .animation(.easeOut(duration: 0.15), value: isSelected)
                // Extended highlight duration for deselected card (2.5s) to help user track it
                .animation(.easeOut(duration: 2.5), value: lastDeselectedCardID)
        )
        .accessibilityIdentifier("CardRow-\(card.id.uuidString)")
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .details:
                NavigationStack {
                    CardDetailView(card: card,
                                   moveAction: { activeSheet = .move },
                                   tagAction: { activeSheet = .tags })
                }
            case .move:
                NavigationStack {
                    UpdateCardFolderView(card: card)
                }
            case .tags:
                NavigationStack {
                    AddNewTagSheet(card: card)
                }
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            CardRowSwipeRight(card: card)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            CardRowSwipeLeft(
                card: card,
                showDetails: { activeSheet = .details },
                moveAction: { activeSheet = .move }
            )
        }
        .contextMenu {
            CardRowContextMenu(
                card: card,
                showDetails: { activeSheet = .details },
                moveAction: { activeSheet = .move },
                tagAction: { activeSheet = .tags }
            )
        }
        .onChange(of: isSelected) { _, newValue in
            handleSelectionChange(newValue: newValue)
        }
        .onAppear {
            // DISABLED: onAppear delete was causing cards to be deleted unexpectedly
            // deleteIfEmptyAndNotSelected()
        }
    }
    
    private func handleSelectionChange(newValue: Bool) {
        if !newValue {
            saveTask?.cancel()
            // Commit drafts on deselect - but only if drafts belong to THIS card
            // This prevents race condition where old card reads new card's drafts
            if let drafts = selectedCardModel.getDraftsForCard(card.id) {
                let latestContent = drafts.content ?? draftContent
                if card.content != latestContent {
                    card.content = latestContent
                }
                if card.cardType == .flashcard {
                    let currentAnswer = card.answer ?? ""
                    let latestAnswer = drafts.answer ?? draftAnswer
                    if currentAnswer != latestAnswer { 
                        card.answer = latestAnswer 
                    }
                }
                try? modelContext.save()
            } else {
                // Drafts don't belong to this card - just use local state
                // This can happen during rapid selection changes
                if card.content != draftContent {
                    card.content = draftContent
                }
                if card.cardType == .flashcard {
                    let currentAnswer = card.answer ?? ""
                    if currentAnswer != draftAnswer {
                        card.answer = draftAnswer
                    }
                }
                try? modelContext.save()
            }
            // Only clear drafts if they belong to this card
            if selectedCardModel.draftCardID == card.id {
                selectedCardModel.clearDrafts()
            }
        } else {
            // Initialize drafts on select
            selectedCardModel.clearDrafts()
            draftContent = card.content
            draftAnswer = card.answer ?? ""
            selectedCardModel.setDraftCardID(card.id)
            selectedCardModel.updateDraft(content: draftContent)
            if card.cardType == .flashcard {
                selectedCardModel.updateDraft(answer: draftAnswer)
            }
        }
    }
}
