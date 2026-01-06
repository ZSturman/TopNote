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
                    } else {
                        HStack(spacing: 6) {
                            // Card type icon with tint color (no text label)
                            Image(systemName: card.cardType.systemImage)
                                .font(.caption)
                                .foregroundColor(card.cardType.tintColor)
                            CardRowContentDisplay(card: card)
                        }
                        
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
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: card.cardType.systemImage)
                        .font(.caption2)
                        .foregroundColor(card.cardType.tintColor)
                    Text(card.cardTypeRaw)
                        .font(.caption2)
                } else {
                    
                    
                    // Folder name with icon if present
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
                    
                    // Tags - truncated to fit available space
                    if let tags = card.tags, !tags.isEmpty {
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
            HStack(alignment: .top, spacing: 8) {
                /* MARK: - IMAGE DISABLED
                // Show thumbnail if content has an image
                if let imageData = card.contentImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                */
                
                Text(card.displayContent)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(isArchived ? .gray : .primary)
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
        
        // MARK: - IMAGE DISABLED
        // @Binding var selectedContentPhoto: PhotosPickerItem?
        // @Binding var selectedAnswerPhoto: PhotosPickerItem?

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
                
                /* MARK: - IMAGE DISABLED - Content image picker and display
                ZStack(alignment: .bottomTrailing) {
                    // TextEditor was inside this ZStack
                    
                    // Content image picker - only show when no image exists
                    if card.contentImageData == nil {
                        PhotosPicker(selection: $selectedContentPhoto, matching: .images) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 18))
                                .foregroundColor(.accentColor)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .padding(8)
                        .buttonStyle(.borderless)
                        .onChange(of: selectedContentPhoto) { _, newValue in
                            Task {
                                if let data = try? await newValue?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    card.setContentImage(uiImage.compressedJPEGData(quality: 0.8))
                                }
                            }
                        }
                    }
                }
                
                // Display content image if present
                if let imageData = card.contentImageData, let uiImage = UIImage(data: imageData) {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Button(action: {
                            card.setContentImage(nil)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                                .padding(4)
                        }
                        .buttonStyle(.borderless)
                        .padding(4)
                    }
                }
                */

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
                    
                    /* MARK: - IMAGE DISABLED - Answer image picker and display
                    ZStack(alignment: .bottomTrailing) {
                        // TextEditor was inside this ZStack
                        
                        // Answer image picker - only show when no image exists
                        if card.answerImageData == nil {
                            PhotosPicker(selection: $selectedAnswerPhoto, matching: .images) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 16))
                                    .foregroundColor(.accentColor)
                                    .padding(6)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            .padding(6)
                            .buttonStyle(.borderless)
                        }
                    }
                    
                    // Display answer image if present
                    if let imageData = card.answerImageData, let uiImage = UIImage(data: imageData) {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 150)
                                .cornerRadius(8)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            Button(action: {
                                card.setAnswerImage(nil)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.black.opacity(0.6)))
                                    .padding(4)
                            }
                            .buttonStyle(.borderless)
                            .padding(4)
                        }
                    }
                    */

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
