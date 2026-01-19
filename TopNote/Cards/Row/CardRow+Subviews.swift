//
//  CardRow+Subviews.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import Foundation
import SwiftUI
import SwiftData
import PhotosUI

extension CardRow {
    struct CardRowMainContent: View {
        @Environment(\.modelContext) private var modelContext
        @EnvironmentObject var selectedCardModel: SelectedCardModel
        
        let card: Card
        let isSelected: Bool

        @Binding var draftContent: String
        @Binding var draftAnswer: String
        @Binding var showingFlashcardAnswer: Bool

        @FocusState.Binding var isContentEditorFocused: Bool

        let folders: [Folder]
        let onPriorityChanged: ((UUID) -> Void)?
        
        var moveAction: () -> Void
        
        // MARK: - IMAGE DISABLED
        // @Binding var selectedContentPhoto: PhotosPickerItem?
        // @Binding var selectedAnswerPhoto: PhotosPickerItem?
        var selectedContentPhoto: PhotosPickerItem? = nil
        var selectedAnswerPhoto: PhotosPickerItem? = nil

        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    CardRowHeader(card: card, isSelected: isSelected)
                    if isSelected {
                        if card.isDeleted {
                            // Show read-only content for deleted cards
                            DeletedCardReadOnlyContent(card: card)
                            // Show restore/delete controls instead of normal inline controls
                            DeletedCardInlineControls(card: card)
                        } else {
                            CardRowEditor(
                                card: card,
                                draftContent: $draftContent,
                                draftAnswer: $draftAnswer,
                                showingFlashcardAnswer: $showingFlashcardAnswer,
                                isContentEditorFocused: _isContentEditorFocused
                                // MARK: - IMAGE DISABLED
                                // selectedContentPhoto: $selectedContentPhoto,
                                // selectedAnswerPhoto: $selectedAnswerPhoto
                            )
                            CardRowInlineControls(
                                card: card,
                                folders: folders,
                                onPriorityChanged: onPriorityChanged,
                                moveAction: moveAction
                            )
                        }
                    } else {
                        HStack(spacing: 6) {
                            // Card type icon with tint color (no text label)
                            Image(systemName: card.cardType.systemImage)
                                .font(.caption)
                                .foregroundColor(card.isDeleted ? .secondary : card.cardType.tintColor)
                            CardRowContentDisplay(card: card)
                        }
                        
                    }
                }
            }
        }
    }
    
    /// Read-only content display for deleted cards when selected
    struct DeletedCardReadOnlyContent: View {
        let card: Card
        @State private var showingAnswer = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                // Content display (read-only)
                Text(card.content.isEmpty ? "Untitled" : card.content)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.08))
                    )
                
                // Show tags if present
                if let tags = card.tags, !tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(Array(tags), id: \.id) { tag in
                            Text("#\(tag.name)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Flashcard answer (read-only)
                if card.cardType == .flashcard {
                    if showingAnswer {
                        Text(card.answer ?? "No answer")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.secondary.opacity(0.06))
                            )
                        
                        Button {
                            withAnimation { showingAnswer = false }
                        } label: {
                            Text("Hide Answer")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    } else {
                        Button {
                            withAnimation { showingAnswer = true }
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
    }
    
    /// Inline controls for deleted cards - restore and delete forever buttons
    struct DeletedCardInlineControls: View {
        @Environment(\.modelContext) private var modelContext
        @EnvironmentObject var selectedCardModel: SelectedCardModel
        let card: Card
        @State private var showDeleteConfirmation = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                // Info message
                Text("This card is in the trash")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                HStack {
                    Spacer()
                    
                    // Restore button
                    Button {
                        card.restore(at: Date())
                        try? modelContext.save()
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Restore")
                                .font(.caption2)
                        }
                        .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // Delete forever button
                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "trash.fill")
                            Text("Delete Forever")
                                .font(.caption2)
                        }
                        .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog(
                        "Permanently Delete?",
                        isPresented: $showDeleteConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Delete Forever", role: .destructive) {
                            // Clear selection first to prevent state issues
                            selectedCardModel.clearSelection()
                            // Use async to let the UI update before deleting
                            DispatchQueue.main.async {
                                modelContext.delete(card)
                                try? modelContext.save()
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This action cannot be undone. The card will be permanently removed.")
                    }
                    
                    Spacer()
                }
            }
            .padding(.vertical, 8)
        }
    }

    struct CardRowFooter: View {
        let card: Card
        @Binding var showingLongInfo: Bool
        @Binding var showingRatingsPolicyInfo: Bool
        @Binding var showingSkipInfo: Bool
        
        private var daysUntilPermanentDeletion: Int? {
            guard let deletedAt = card.deletedAt else { return nil }
            let thirtyDaysLater = Calendar.current.date(byAdding: .day, value: 30, to: deletedAt) ?? deletedAt
            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: thirtyDaysLater).day ?? 0
            return max(0, daysRemaining)
        }
        
        private var daysLeftText: String {
            guard let days = daysUntilPermanentDeletion else { return "" }
            return days == 1 ? "1 day left" : "\(days) days left"
        }

        var body: some View {
            VStack(alignment: .trailing) {
                if card.isDeleted {
                    // Show days until permanent deletion for deleted cards
                    HStack {
                        Spacer()
                        if daysUntilPermanentDeletion != nil {
                            Text(daysLeftText)
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                } else {
                    if !card.isRecurring, !card.displayedRecurringMessageShort.isEmpty {
                        CardRecurringMessage(card: card, showingLongInfo: $showingLongInfo, showingRatingsPolicyInfo: $showingRatingsPolicyInfo, showingSkipInfo: $showingSkipInfo)
                    }
                }
            }
            .padding(2)
        }
    }

    struct CardRowHeader: View {
        let card: Card
        let isSelected: Bool
        
        private var deletionDateText: String {
            guard let deletedAt = card.deletedAt else { return "" }
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Deleted \(formatter.localizedString(for: deletedAt, relativeTo: Date()))"
        }

        var body: some View {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: card.cardType.systemImage)
                        .font(.caption2)
                        .foregroundColor(card.isDeleted ? .secondary : card.cardType.tintColor)
                    Text(card.cardTypeRaw)
                        .font(.caption2)
                } else {
                    
                    
                    // Folder name with icon if present
                    if let folder = card.folder {
                        HStack(spacing: 3) {
                            Image(systemName: "folder")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(folder.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    // Tags - truncated to fit available space (hide for deleted cards to save space)
                    if !card.isDeleted, let tags = card.tags, !tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(Array(tags.prefix(3)), id: \.id) { tag in
                                Text("#\(tag.name)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            if tags.count > 3 {
                                Text("+\(tags.count - 3)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .lineLimit(1)
                    }
                }
                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    // Show deletion date for deleted cards, otherwise show timing
                    if card.isDeleted {
                        Text(deletionDateText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else                 if card.isArchived {
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
                    } else {
                        HStack(spacing: 3) {
                            if !card.isArchived {
                                Image(systemName: card.isEnqueue(currentDate: Date()) ? "clock.arrow.circlepath" : "calendar")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Text(card.displayedDateForQueue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if !card.isDeleted && !card.isArchived && card.priority != .none {
                                    Image(systemName: card.priority.iconName)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                
                            }
                        }
                    }

                    if isSelected && !card.isDeleted && card.isRecurring && !card.displayedScheduleForRow.isEmpty {
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
        
        private var isDeleted: Bool {
            card.isDeleted
        }

        var body: some View {
            HStack(alignment: .top, spacing: 8) {
                
                Text(card.displayContent)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(isArchived || isDeleted ? .secondary : .primary)
                    .strikethrough(card.cardType == .todo && card.isComplete, color: .gray)
            }
        }
    }

    struct CardRowEditor: View {
        let card: Card

        @Binding var draftContent: String
        @Binding var draftAnswer: String
        @Binding var showingFlashcardAnswer: Bool

        @FocusState.Binding var isContentEditorFocused: Bool

        @EnvironmentObject var selectedCardModel: SelectedCardModel
        @Environment(\.modelContext) var modelContext
        

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                // MARK: - IMAGE DISABLED - Removed ZStack wrapper for PhotosPicker
                TextEditor(text: $draftContent)
                    .font(.headline.weight(.semibold))
                    .frame(minHeight: 80, maxHeight: 220)
                    .multilineTextAlignment(.leading)
                    .disableAutocorrection(false)
                    .textInputAutocapitalization(.sentences)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor.opacity(0.12))
                    )
                    .focused($isContentEditorFocused)
                    .accessibilityIdentifier("Card Content Editor")
                    .onAppear {
                        // Initialize draft content from card
                        draftContent = card.content
                        selectedCardModel.updateDraft(content: card.content)
                        if card.cardType == .flashcard {
                            draftAnswer = card.answer ?? ""
                            selectedCardModel.updateDraft(answer: draftAnswer)
                        }
                    }
                    .onChange(of: draftContent) { _, newValue in
                        // Cache draft locally without touching the model to avoid heavy per-keystroke work
                        selectedCardModel.updateDraft(content: newValue)
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
                        // MARK: - IMAGE DISABLED
                        // selectedAnswerPhoto: $selectedAnswerPhoto
                    )
                    .onChange(of: draftAnswer) { _, newValue in
                        selectedCardModel.updateDraft(answer: newValue)
                    }
                    /* MARK: - IMAGE DISABLED - Answer image picker
                    .onChange(of: selectedAnswerPhoto) { _, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                card.setAnswerImage(uiImage.compressedJPEGData(quality: 0.8))
                            }
                        }
                    }
                    */
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
        
        var moveAction: () -> Void

        @EnvironmentObject var selectedCardModel: SelectedCardModel

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                FolderMenu(card: card, folders: folders, moveAction: moveAction)

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
        // MARK: - IMAGE DISABLED
        // @Binding var selectedAnswerPhoto: PhotosPickerItem?

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                if showingFlashcardAnswer {
                    // MARK: - IMAGE DISABLED - Removed ZStack wrapper for PhotosPicker
                    TextEditor(text: $draftAnswer)
                        .font(.subheadline)
                        .frame(minHeight: 80, maxHeight: 200)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.accentColor.opacity(0.10))
                        )
                        .disableAutocorrection(false)
                        .textInputAutocapitalization(.sentences)
                        .padding(.vertical, 2)
                        .accessibilityIdentifier("Card Answer Editor")
                    

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
                    .accessibilityIdentifier("Hide Answer")
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
                    .accessibilityIdentifier("Show Answer")
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
            if card.isRecurring || card.displayedRecurringMessageShort.isEmpty {
                EmptyView()
            } else {
                ViewThatFits(in: .horizontal) {
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
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.secondary)
                            .accessibilityLabel(Text(card.displayedRecurringMessageShort))
                        Button {
                            showingLongInfo = true
                            // Close others
                            showingRatingsPolicyInfo = false
                            showingSkipInfo = false
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
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
        }
    }

    
    
    @ViewBuilder fileprivate func flashcardAnswerView() -> some View {
        VStack(alignment: .leading) {
            if showingFlashcardAnswer {
                TextEditor(text: $draftAnswer)
                    .font(.subheadline)
                    .frame(minHeight: 80, maxHeight: 200)
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
                    ForEach(Array(tags), id: \.id) { tag in
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
            ForEach(Array(card.tags ?? []), id: \.id) { tag in
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
