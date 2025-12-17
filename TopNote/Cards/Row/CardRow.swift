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
import PhotosUI

struct CardRow: View {
    @EnvironmentObject var selectedCardModel: SelectedCardModel
    @Environment(\.modelContext) var modelContext

    var card: Card
    var onCommit: (() -> Void)? = nil
    var onPriorityChanged: ((UUID) -> Void)? = nil
    var lastDeselectedCardID: UUID? = nil

    @Query var tags: [CardTag]
    @Query var folders: [Folder]

    // Selection / editing
    @State var showingFlashcardAnswer = false
    @State var draftContent: String = ""
    @State var draftAnswer: String = ""
    // MARK: - IMAGE DISABLED
    // @State var selectedContentPhoto: PhotosPickerItem?
    // @State var selectedAnswerPhoto: PhotosPickerItem?
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
        // Trim whitespace/newlines
        let contentIsEmpty = card.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        // MARK: - IMAGE DISABLED
        // let hasNoImage = card.contentImageData == nil
        // let hasPendingImage = selectedContentPhoto != nil || selectedAnswerPhoto != nil
        // let shouldDelete = contentIsEmpty && hasNoImage && !hasPendingImage
        let shouldDelete = contentIsEmpty
        
        // Only log when content is empty (the interesting cases) to reduce log spam
        if contentIsEmpty {
            print("📝 [CardRow deleteIfEmpty] Card ID: \\(card.id), isSelected: \\(isSelected), contentIsEmpty: \\(contentIsEmpty), content: '\\(card.content)'")
        }
        
        // Allow cards with only an image (empty content is OK if there's an image)
        // Only delete if both content is empty AND no image exists AND no pending image selection
        if !isSelected && shouldDelete {
            print("📝 [CardRow deleteIfEmpty] DELETING card because not selected, content empty, and no image")
            modelContext.delete(card)
            try? modelContext.save()
        }
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
                .animation(.easeOut(duration: 0.5), value: isSelected)
                .animation(.easeOut(duration: 0.5), value: lastDeselectedCardID)
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
            deleteIfEmptyAndNotSelected()
        }
    }
    
    private func handleSelectionChange(newValue: Bool) {
        if !newValue {
            saveTask?.cancel()
            // Commit drafts on deselect
            let latestContent = selectedCardModel.draftContent ?? draftContent
            if card.content != latestContent {
                card.content = latestContent
            }
            if card.cardType == .flashcard {
                let currentAnswer = card.answer ?? ""
                let latestAnswer = selectedCardModel.draftAnswer ?? draftAnswer
                if currentAnswer != latestAnswer { card.answer = latestAnswer }
            }
            do {
                try modelContext.save()
            } catch {
                print("📝 [CardRow handleSelectionChange] ERROR saving: \(error)")
            }
            selectedCardModel.clearDrafts()
            deleteIfEmptyAndNotSelected()
        } else {
            // Initialize drafts on select
            selectedCardModel.clearDrafts()
            draftContent = card.content
            selectedCardModel.updateDraft(content: draftContent)
            if card.cardType == .flashcard {
                draftAnswer = card.answer ?? ""
                selectedCardModel.updateDraft(answer: draftAnswer)
            }
        }
    }
}
