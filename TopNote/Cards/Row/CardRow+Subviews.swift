//
//  CardRow+Subviews.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import Foundation
import SwiftUI
import SwiftData

extension CardRow {
    struct CardRowMainContent: View {
        let card: Card
        let isSelected: Bool

        @Binding var draftContent: String
        @Binding var draftAnswer: String
        @Binding var showingFlashcardAnswer: Bool

        @FocusState.Binding var isContentEditorFocused: Bool

        let folders: [Folder]
        let onPriorityChanged: ((UUID) -> Void)?

        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    CardRowHeader(card: card, isSelected: isSelected)
                    if isSelected {
                        CardRowEditor(
                            card: card,
                            draftContent: $draftContent,
                            draftAnswer: $draftAnswer,
                            showingFlashcardAnswer: $showingFlashcardAnswer,
                            isContentEditorFocused: _isContentEditorFocused
                        )
                        CardRowInlineControls(
                            card: card,
                            folders: folders,
                            onPriorityChanged: onPriorityChanged,
                        )
                    } else {
                        CardRowContentDisplay(card: card)
                    }
                }
            }
        }
    }

    struct CardRowFooter: View {
        let card: Card
        @Binding var showingLongInfo: Bool
        @Binding var showingRatingsPolicyInfo: Bool
        @Binding var showingSkipInfo: Bool
        

        var body: some View {
            VStack(alignment: .trailing) {
                CardSeenAndSkipCount(card: card)
                if !card.isRecurring, !card.displayedRecurringMessageShort.isEmpty {
                    CardRecurringMessage(card: card, showingLongInfo: $showingLongInfo, showingRatingsPolicyInfo: $showingRatingsPolicyInfo, showingSkipInfo: $showingSkipInfo)
                }
            }
            .padding(2)
        }
    }

    struct CardRowHeader: View {
        let card: Card
        let isSelected: Bool

        var body: some View {
            HStack {
                Image(systemName: card.cardType.systemImage)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(card.cardType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(card.displayedDateForQueue)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if isSelected && card.isRecurring && !card.displayedScheduleForRow.isEmpty {
                        Text(card.displayedScheduleForRow)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    struct CardRowContentDisplay: View {
        let card: Card

        private var isArchived: Bool {
            card.isArchived
        }

        var body: some View {
            Text(card.displayContent)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .foregroundColor(isArchived ? .gray : .primary)
                .strikethrough(card.cardType == .todo && card.isComplete, color: .gray)
        }
    }

    struct CardRowEditor: View {
        let card: Card

        @Binding var draftContent: String
        @Binding var draftAnswer: String
        @Binding var showingFlashcardAnswer: Bool

        @FocusState.Binding var isContentEditorFocused: Bool

        @EnvironmentObject var selectedCardModel: SelectedCardModel

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                TextEditor(text: $draftContent)
                    .font(.headline.weight(.semibold))
                    .frame(minHeight: 44, maxHeight: 80)
                    .multilineTextAlignment(.leading)
                    .disableAutocorrection(false)
                    .textInputAutocapitalization(.sentences)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor.opacity(0.12))
                    )
                    .focused($isContentEditorFocused)
                    .onAppear {
                        if selectedCardModel.isNewlyCreated {
                            isContentEditorFocused = true
                        }
                        draftContent = card.content
                        if card.cardType == .flashcard {
                            draftAnswer = card.answer ?? ""
                        }
                    }

                if card.cardType != .flashcard {
                    TagInputView(card: card)
                        .padding(.vertical, 4)
                }

                if card.cardType == .flashcard {
                    FlashcardAnswerInline(
                        card: card,
                        draftAnswer: $draftAnswer,
                        showingFlashcardAnswer: $showingFlashcardAnswer
                    )
                    if selectedCardModel.selectedCard?.id == card.id {
                        TagInputView(card: card)
                            .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    struct CardRowInlineControls: View {
        let card: Card
        let folders: [Folder]
        let onPriorityChanged: ((UUID) -> Void)?
        let recurringOffTip = RecurringOffTip()
        let policiesTip = PoliciesTip()

        @EnvironmentObject var selectedCardModel: SelectedCardModel

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                FolderMenu(card: card, folders: folders)

                HStack {
                    Spacer()
                    RecurringButton(isRecurring: card.isRecurring) {
                        card.isRecurring.toggle()
                        if !card.isRecurring {
                            Task { await RecurringOffTip.toggledRecurringOffEvent.donate() }
                        }
                    }
                    .popoverTip(recurringOffTip, arrowEdge: .bottom)

                    Spacer()

                    PriorityMenu(
                        selected: Binding(
                            get: { card.priority },
                            set: { newPriority in
                                if let callback = onPriorityChanged {
                                    callback(card.id)
                                    DispatchQueue.main.async {
                                        card.priority = newPriority
                                    }
                                } else {
                                    card.priority = newPriority
                                }
                            }
                        )
                    )

                    Spacer()

                    IntervalMenu(
                        selected: Binding(
                            get: { RepeatInterval(hours: card.initialRepeatInterval) },
                            set: {
                                card.initialRepeatInterval = $0.hours ?? 24
                                card.repeatInterval = $0.hours ?? 24
                            }
                        ),
                        isRecurring: card.isRecurring,
                        currentHours: card.repeatInterval
                    )

                    Spacer()

                    CardPoliciesMenu(card: card)
                        .popoverTip(policiesTip, arrowEdge: .top)
                        .onAppear {
                            if selectedCardModel.selectedCard?.id == card.id {
                                Task { await PoliciesTip.openedPoliciesEvent.donate() }
                            }
                        }

                    Spacer()
                }
            }
            .padding(.top, 2)
            .padding(.bottom, 4)
        }
    }

    struct FlashcardAnswerInline: View {
        let card: Card
        @Binding var draftAnswer: String
        @Binding var showingFlashcardAnswer: Bool

        var body: some View {
            VStack(alignment: .leading) {
                if showingFlashcardAnswer {
                    TextEditor(text: $draftAnswer)
                        .font(.subheadline)
                        .frame(minHeight: 44, maxHeight: 160)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.accentColor.opacity(0.10))
                        )
                        .disableAutocorrection(false)
                        .textInputAutocapitalization(.sentences)
                        .padding(.vertical, 2)

                    Button {
                        withAnimation {
                            showingFlashcardAnswer = false
                        }
                    } label: {
                        Text("Hide Answer")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                } else {
                    Button {
                        withAnimation {
                            draftAnswer = card.answer ?? ""
                            showingFlashcardAnswer = true
                        }
                    } label: {
                        Text("Show Answer")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
        }
    }
    
    struct CardRecurringMessage: View {
        var card: Card
        @Binding var showingLongInfo: Bool
        @Binding var showingRatingsPolicyInfo: Bool
        @Binding var showingSkipInfo: Bool
        
        var body: some View {
            HStack(spacing: 4) {
                Text(card.displayedRecurringMessageShort)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Button {
                    showingLongInfo = true
                    // Close others
                    showingRatingsPolicyInfo = false
                    showingSkipInfo = false
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.caption2)
                }
                .buttonStyle(BorderlessButtonStyle())
                .confirmationDialog(
                    "Card Recurring Info",
                    isPresented: $showingLongInfo,
                    titleVisibility: .hidden
                ) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(card.displayedRecurringMessageLong)
                }
          
            }
        }
    }
    
    struct CardSeenAndSkipCount: View {
        var card: Card
        
        var body: some View {
            HStack(spacing: 12) {
                Spacer()
                if card.isArchived {
                    if let archivedDate = card.removals.last {
                        let daysAgo = Calendar.current.dateComponents([.day], from: archivedDate, to: Date()).day ?? 0
                        if daysAgo == 0 {
                            Text("Archived today")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else if daysAgo == 1 {
                            Text("Archived yesterday")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Archived \(daysAgo) days ago")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if card.priority != .none {
                    Text("Priority: \(card.priorityRaw)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    
    @ViewBuilder fileprivate func flashcardAnswerView() -> some View {
        VStack(alignment: .leading) {
            if showingFlashcardAnswer {
                TextEditor(text: $draftAnswer)
                    .font(.subheadline)
                    .frame(minHeight: 44, maxHeight: 160)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor.opacity(0.10))
                    )
                    .disableAutocorrection(false)
                    .textInputAutocapitalization(.sentences)
                    .padding(.vertical, 2)
                    .onChange(of: draftAnswer) { _, _ in
                        guard isSelected else { return }
                        saveTask?.cancel()
                        saveTask = Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 300_000_000)
                            if isSelected {
                                card.answer = draftAnswer
                            }
                        }
                    }

                Button {
                    withAnimation {
                        showingFlashcardAnswer = false
                    }
                } label: {
                    Text("Hide Answer")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .buttonStyle(BorderlessButtonStyle())
            } else {
                Button {
                    withAnimation {
                        draftAnswer = card.answer ?? ""
                        showingFlashcardAnswer = true
                    }
                } label: {
                    Text("Show Answer")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }
    
    @ViewBuilder fileprivate func cardFolderAndTagsView() -> some View {
        HStack {
            if let folder = card.folder {
                Label(folder.name, systemImage: "folder")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            if let tags = card.tags, !tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(Array(tags), id: \.self) { tag in
                        Label("#\(tag.name)", systemImage: "tag")
                            .labelStyle(.titleOnly)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(4)
                            .background(Capsule().fill(Color.secondary.opacity(0.2)))
                    }
                }
            }
            Spacer()
        }
    }

    
    @ViewBuilder fileprivate func readOnlyTagsView() -> some View {
        HStack(spacing: 6) {
            ForEach(Array(card.tags ?? []), id: \.self) { tag in
                Text("#\(tag.name)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.2))
                    )
            }
        }
    }
}
