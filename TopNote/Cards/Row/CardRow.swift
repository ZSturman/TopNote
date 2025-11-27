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
    var onCommit: (() -> Void)? = nil
    var onPriorityChanged: ((UUID) -> Void)? = nil

    @Query var tags: [CardTag]
    @Query var folders: [Folder]

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
        // Trim whitespace/newlines
        let isEmpty = card.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if !isSelected && isEmpty {
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
                onPriorityChanged: onPriorityChanged
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
                .fill(isSelected ? card.cardType.tintColor.opacity(0.12) : Color.clear)
        )
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
            if card.content != draftContent { card.content = draftContent }
            if card.cardType == .flashcard {
                let currentAnswer = card.answer ?? ""
                if currentAnswer != draftAnswer { card.answer = draftAnswer }
            }
            try? modelContext.save()
            deleteIfEmptyAndNotSelected()
        } else {
            // Initialize drafts on select
            draftContent = card.content
            if card.cardType == .flashcard { draftAnswer = card.answer ?? "" }
        }
    }
}


//
//
//import Foundation
//import SwiftUI
//import SwiftData
//import WidgetKit
//import TipKit
//
//struct CardRowOld: View {
//    @EnvironmentObject var selectedCardModel: SelectedCardModel
//    @Environment(\.modelContext) private var modelContext
//    var card: Card
//
//    var onCommit: (() -> Void)? = nil
//    var onPriorityChanged: ((UUID) -> Void)? = nil
//
//    var isEnqueued: Bool {
//        card.isEnqueue(currentDate: Date()) && !card.isArchived
//    }
//    var isArchived: Bool {
//        card.isArchived
//    }
//    
//    var isSelected: Bool {
//        selectedCardModel.selectedCard?.id == card.id
//    }
//    
//
//    @State private var showingFlashcardAnswer = false
//    @State private var isEditingAnswer = false
//    @State private var showingLongInfo = false
//    @State private var showingRatingsPolicyInfo = false
//    
//    @State private var showingSkipInfo = false
//    
//    @State private var showingEnqueueIntervalInfo = false
//    
//    @State private var draftContent: String = ""
//    @State private var draftAnswer: String = ""
//    @State private var saveTask: Task<Void, Never>? = nil
//    
//    enum CardRowSheet: Identifiable {
//        case details, move, tags
//        var id: Int {
//            switch self {
//            case .details: return 0
//            case .move: return 1
//            case .tags: return 2
//            }
//        }
//    }
//    @State private var activeSheet: CardRowSheet? = nil
//
//    @FocusState private var isContentEditorFocused: Bool
//    @FocusState private var isAnswerEditorFocused: Bool
//
//    @Query var tags: [CardTag]
//    @Query var folders: [Folder]
//    
//    // Tips
//    let policiesTip = PoliciesTip()
//    let flashcardRatingPolicyTip = FlashcardRatingPolicyTip()
//    let firstNoteTip = FirstNoteTip_Skip()
//    let firstTodoTip = FirstTodoTip_Skip()
//    let firstFlashcardTip = FirstFlashcardTip_Skip()
//    let recurringOffTip = RecurringOffTip()
//
//
//
//    
//    
//    
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            HStack {
//
//                VStack(alignment: .leading, spacing: 6) {
//                    HStack {
//                        Image(systemName: card.cardType.systemImage)
//                            .font(.caption2)
//                            .foregroundColor(.secondary)
//                        Text(card.cardType.rawValue)
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                    
//                        Spacer()
//                        
//                        VStack(alignment: .trailing, spacing: 2) {
//                            Text(card.displayedDateForQueue)
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                            
//                            if isSelected && card.isRecurring && !card.displayedScheduleForRow.isEmpty {
//                                Text(card.displayedScheduleForRow)
//                                    .font(.caption2)
//                                    .foregroundColor(.secondary)
//                            }
//                            }
//                        }
//                    
//                    if isSelected {
//                        TextEditor(text: $draftContent)
//                        .font(.headline.weight(.semibold))
//                        .frame(minHeight: 44, maxHeight: 80)
//                        .multilineTextAlignment(.leading)
//                        .disableAutocorrection(false)
//                        .textInputAutocapitalization(.sentences)
//                        .background(
//                            RoundedRectangle(cornerRadius: 8)
//                                .fill(Color.accentColor.opacity(0.12))
//                        )
//                        .focused($isContentEditorFocused)
//                        .onAppear {
//                            if isSelected && selectedCardModel.isNewlyCreated {
//                                isContentEditorFocused = true
//                            }
//                            draftContent = card.content
//                            if card.cardType == .flashcard { draftAnswer = card.answer ?? "" }
//                        }
//                        .onChange(of: selectedCardModel.isNewlyCreated) {
//                            if isSelected && selectedCardModel.isNewlyCreated {
//                                isContentEditorFocused = true
//                                draftContent = card.content
//                                if card.cardType == .flashcard { draftAnswer = card.answer ?? "" }
//                            }
//                        }
//                        .onTapGesture {
//                            isContentEditorFocused = true
//                        }
//                        .onChange(of: draftContent) { _, _ in
//                            guard isSelected else { return }
//                            saveTask?.cancel()
//                            saveTask = Task { @MainActor in
//                                try? await Task.sleep(nanoseconds: 300_000_000)
//                                if isSelected {
//                                    card.content = draftContent
//                                    try? modelContext.save()
//                                }
//                            }
//                        }
//                        
//                        if card.cardType != .flashcard {
//                            TagInputView(card: card)
//                                .padding(.vertical, 4)
//                        }
//                        
//                        if card.cardType == .flashcard {
//                            flashcardAnswerView()
//                                .onAppear {
//                                    if isSelected && selectedCardModel.isNewlyCreated {
//                                        showingFlashcardAnswer = true
//                                    }
//                                }
//                                .onChange(of: isSelected) { _, newValue in
//                                    if card.cardType == .flashcard && newValue && selectedCardModel.isNewlyCreated {
//                                        showingFlashcardAnswer = true
//                                    }
//                                }
//                                .onChange(of: selectedCardModel.isNewlyCreated) { _, newValue in
//                                    if card.cardType == .flashcard && isSelected && newValue {
//                                        showingFlashcardAnswer = true
//                                    }
//                                }
//                            if isSelected {
//                                TagInputView(card: card)
//                                .padding(.vertical, 4)
//                        }
//                        }
//                    } else {
//                        Text(card.displayContent)
//                            .font(.headline)
//                            .fontWeight(.semibold)
//                            .lineLimit(2)
//                            .multilineTextAlignment(.leading)
//                            .foregroundColor(isArchived ? .gray : .primary)
//                            .strikethrough(card.cardType == .todo && card.isComplete, color: .gray)
//   
//                    }
//
//                    // New section for inline settings and controls when selected
//                    if isSelected {
//                        VStack(alignment: .leading, spacing: 10) {
//                            
//                            FolderMenu(card: card, folders: folders)
//                        
//                            HStack{
//                                Spacer()
//                                RecurringButton(isRecurring: card.isRecurring, action: { 
//                                    card.isRecurring.toggle()
//                                    if !card.isRecurring {
//                                        Task { await RecurringOffTip.toggledRecurringOffEvent.donate() }
//                                    }
//                                })
//                                .popoverTip(recurringOffTip, arrowEdge: .bottom)
//                                Spacer()
//                                PriorityMenu(selected: Binding(
//                                    get: { card.priority },
//                                    set: { newPriority in
//                                        // Notify BEFORE changing priority and force immediate update
//                                        if let callback = onPriorityChanged {
//                                            callback(card.id)
//                                            // Small delay to ensure state propagates before priority changes
//                                            DispatchQueue.main.async {
//                                                card.priority = newPriority
//                                            }
//                                        } else {
//                                            card.priority = newPriority
//                                        }
//                                    }
//                                ))
//                                Spacer()
//                                IntervalMenu(
//                                    selected: Binding(
//                                        get: { RepeatInterval(hours: card.initialRepeatInterval) },
//                                        set: { 
//                                            card.initialRepeatInterval = $0.hours ?? 24
//                                            card.repeatInterval = $0.hours ?? 24
//                                        }
//                                    ),
//                                    isRecurring: card.isRecurring,
//                                    currentHours: card.repeatInterval
//                                )
//                                Spacer()
//                                policiesMenu()
//                                .popoverTip(policiesTip, arrowEdge: .top)
//                                .onAppear {
//                                    if isSelected {
//                                        Task { await PoliciesTip.openedPoliciesEvent.donate() }
//                                    }
//                                }
//                                Spacer()
//                            }
//
//                        }
//                        .padding(.top, 2)
//                        .padding(.bottom, 4)
//                    }
//                }
//            }
//
//
//            
//            if !isSelected {
//                cardFolderAndTagsView()
//                    .padding(.top, 4)
//            }
//            
//            
//            VStack(alignment: .trailing) {
//                seenAndSkipCountDisplay()
//                if !card.isRecurring, !card.displayedRecurringMessageShort.isEmpty {
//                    recurringMessageInfo()
//                    
//                }
//               
//            }
//            .padding(2)
//       
//        }
//        .padding(.vertical, 8)
//        .padding(.horizontal, 4)
//        .background(
//            RoundedRectangle(cornerRadius: 8)
//                .fill(isSelected ? card.cardType.tintColor.opacity(0.12) : Color.clear)
//        )
//
//        .swipeActions(edge: .leading, allowsFullSwipe: true) {
//            CardRowSwipeRight(card: card)
//        }
//        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
//            CardRowSwipeLeft(card: card, showDetails: { activeSheet = .details }, moveAction: { activeSheet = .move })
//        }
//        .contextMenu {
//            CardRowContextMenu(
//                card: card,
//                showDetails: { activeSheet = .details },
//                moveAction: { activeSheet = .move },
//                tagAction: { activeSheet = .tags }
//            )
//        }
//        // Auto-delete when not selected and content is empty
//        .onChange(of: isSelected) { _, newValue in
//
//        }
//        .onAppear {
//            deleteIfEmptyAndNotSelected()
//        }
//    }
//}
