//
//  CardRow.swift
//  TopNote
//
//  Created by Zachary Sturman on 7/28/25.
//

import Foundation
import SwiftUI
import SwiftData
import WidgetKit
import TipKit

// MARK: - CardRow
/// A single row representing a Card, including swipe actions, context menu, and primary action.
///
/// Focus behavior:
/// - When a card is selected and `selectedCardModel.isNewlyCreated`, auto-focus the `content` (and `answer` for flashcards) TextEditor.
/// - Otherwise, TextEditors are not focused by default, but will focus when tapped.
struct CardRow: View {
    @EnvironmentObject var selectedCardModel: SelectedCardModel
    @Environment(\.modelContext) private var modelContext
    var card: Card

    var onCommit: (() -> Void)? = nil

    var isEnqueued: Bool {
        card.isEnqueue(currentDate: Date()) && !card.isArchived
    }
    var isArchived: Bool {
        card.isArchived
    }
    
    var isSelected: Bool {
        selectedCardModel.selectedCard?.id == card.id
    }
    

    @State private var showingFlashcardAnswer = false
    @State private var isEditingAnswer = false
    @State private var showingLongInfo = false
    @State private var showingRatingsPolicyInfo = false
    
    @State private var showingSkipInfo = false
    
    @State private var showingEnqueueIntervalInfo = false
    
    @State private var draftContent: String = ""
    @State private var draftAnswer: String = ""
    @State private var saveTask: Task<Void, Never>? = nil
    
    enum CardRowSheet: Identifiable {
        case details, move, tags
        var id: Int {
            switch self {
            case .details: return 0
            case .move: return 1
            case .tags: return 2
            }
        }
    }
    @State private var activeSheet: CardRowSheet? = nil

    @FocusState private var isContentEditorFocused: Bool
    @FocusState private var isAnswerEditorFocused: Bool

    @Query var tags: [CardTag]
    @Query var folders: [Folder]
    
    // Tips
    let policiesTip = PoliciesTip()
    let flashcardRatingPolicyTip = FlashcardRatingPolicyTip()
    let firstNoteTip = FirstNoteTip_Skip()
    let firstTodoTip = FirstTodoTip_Skip()
    let firstFlashcardTip = FirstFlashcardTip_Skip()
    let recurringOffTip = RecurringOffTip()

    @ViewBuilder fileprivate func seenAndSkipCountDisplay() -> some View {
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
                            try? modelContext.save()
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
    
    @ViewBuilder fileprivate func recurringMessageInfo() -> some View {
        HStack(spacing: 4) {
            Text(card.displayedRecurringMessageShort)
                .font(.caption2)
                .foregroundColor(.secondary)
            Button {
                showingLongInfo = true
                // Close others
                showingRatingsPolicyInfo = false
                //showingRecurringInfo = false
                showingSkipInfo = false
                //showingResetInfo = false
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
    
    fileprivate struct FolderMenu: View {
        var card: Card
        var folders: [Folder]

        @State private var showMenu = false
        var body: some View {
            Menu {
                Button("New Folder...") { showMenu = true }
                Divider()
                ForEach(folders.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { folder in
                    Button(action: {
                        card.folder = folder
                    }) {
                        HStack {
                            Text(folder.name)
                            if card.folder == folder {
                                Spacer()
                                Image(systemName: "checkmark").foregroundColor(.blue)
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "folder")
                    Text(card.folder?.name ?? "Choose folder...")
                }
                .font(.subheadline)
            }
        }
    }
    

    

    
    @ViewBuilder fileprivate func policiesMenu() -> some View {
        Menu {
            
            if card.cardType == .todo {
                
                
                Toggle(isOn: Binding(
                    get: { card.resetRepeatIntervalOnComplete },
                    set: { card.resetRepeatIntervalOnComplete = $0 }
                )) {
                    Label("Reset Interval On Complete", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                }
                
            }
                
            Menu {

                // Enable skip toggle
                Toggle(isOn: Binding(
                    get: { card.skipEnabled },
                    set: { card.skipEnabled = $0 }
                )) {
                    Label("Enable Skip", systemImage: "arrow.trianglehead.counterclockwise.rotate.90")
                }
                
                if !card.skipEnabled {
                    Text("Skipping disabled")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                Picker("On Skip", selection: Binding(
                    get: { card.skipPolicy },
                    set: { card.skipPolicy = $0 }
                )) {
                    ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                        Text(policy.rawValue).tag(policy)
                    }
                }
                .pickerStyle(.inline)
                .font(.subheadline)
                
                
                                        VStack(alignment: .leading, spacing: 8) {
                                            ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                                                if card.cardType == .note {
                                                    // For notes, reverse the wording
                                                    Text("• \(policy.rawValue): \(policy.skipDescriptionForNote)")
                                                } else {
                                                    Text("• \(policy.rawValue): \(policy.shortDescription(for: .hard))")
                                                }
                                            }
                                        }

            } label: {
                HStack(spacing: 4) {
                    Text("On Skip:")
                    Text(card.skipPolicy.rawValue)
                        .fontWeight(.semibold)
                }
            }
            .overlay {
                if card.cardType == .note {
                    Color.clear.popoverTip(firstNoteTip, arrowEdge: .top)
                } else if card.cardType == .todo {
                    Color.clear.popoverTip(firstTodoTip, arrowEdge: .top)
                } else {
                    Color.clear.popoverTip(firstFlashcardTip, arrowEdge: .top)
                }
            }
            .onAppear {
                Task {
                    switch card.cardType {
                    case .note:
                        await FirstNoteTip_Skip.createdFirstNoteEvent.donate()
                    case .todo:
                        await FirstTodoTip_Skip.createdFirstTodoEvent.donate()
                    case .flashcard:
                        await FirstFlashcardTip_Skip.createdFirstFlashcardEvent.donate()
                    }
                }
            }
            
            
            if card.cardType == .flashcard {
                Divider()
                VStack(alignment: .leading, spacing: 8) {

                    
                    Text("Ratings Repeat Policy")
                        .font(.subheadline.weight(.semibold))
                    
                    
                    .onAppear {
                        Task { await FlashcardRatingPolicyTip.openedFlashcardPoliciesEvent.donate() }
                    }
                    
                    Menu {
                        Text("Easy moves the card further out.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                            Button(action: {
                                card.ratingEasyPolicy = policy
                            }) {
                                HStack {
                                    Text(policy.rawValue)
                                    if card.ratingEasyPolicy == policy {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                                Text("• \(policy.rawValue): \(policy.shortDescription(for: .easy))")
                                    .font(.caption)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("On Easy:")
                            Text(card.ratingEasyPolicy.rawValue)
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                    .menuActionDismissBehavior(.disabled)

                    Menu {
                        Text("Good keeps the normal schedule.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                            Button(action: {
                                card.ratingMedPolicy = policy
                            }) {
                                HStack {
                                    Text(policy.rawValue)
                                    if card.ratingMedPolicy == policy {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                                Text("• \(policy.rawValue): \(policy.shortDescription(for: .good))")
                                    .font(.caption)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("On Good:")
                            Text(card.ratingMedPolicy.rawValue)
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                    .menuActionDismissBehavior(.disabled)

                    Menu {
                        Text("Hard brings it back sooner for review.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                            Button(action: {
                                card.ratingHardPolicy = policy
                            }) {
                                HStack {
                                    Text(policy.rawValue)
                                    if card.ratingHardPolicy == policy {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                                Text("• \(policy.rawValue): \(policy.shortDescription(for: .hard))")
                                    .font(.caption)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("On Hard:")
                            Text(card.ratingHardPolicy.rawValue)
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                    .menuActionDismissBehavior(.disabled)
                }
            }
        } label: {
            HStack {
                Image(systemName: "shield.lefthalf.fill")
                    .foregroundColor(.primary)
                Text("Policies")
                    .foregroundColor(.primary)
  
            }
            
            .font(.subheadline)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.5))
            )
            .contentShape(Rectangle())
        }
        .menuActionDismissBehavior(.disabled)
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
            HStack {

                VStack(alignment: .leading, spacing: 6) {
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
                    
                    if isSelected {
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
                            if isSelected && selectedCardModel.isNewlyCreated {
                                isContentEditorFocused = true
                            }
                            draftContent = card.content
                            if card.cardType == .flashcard { draftAnswer = card.answer ?? "" }
                        }
                        .onChange(of: selectedCardModel.isNewlyCreated) {
                            if isSelected && selectedCardModel.isNewlyCreated {
                                isContentEditorFocused = true
                                draftContent = card.content
                                if card.cardType == .flashcard { draftAnswer = card.answer ?? "" }
                            }
                        }
                        .onTapGesture {
                            isContentEditorFocused = true
                        }
                        .onChange(of: draftContent) { _, _ in
                            guard isSelected else { return }
                            saveTask?.cancel()
                            saveTask = Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 300_000_000)
                                if isSelected {
                                    card.content = draftContent
                                    try? modelContext.save()
                                }
                            }
                        }
                        
                        if card.cardType != .flashcard {
                            TagInputView(card: card)
                                .padding(.vertical, 4)
                        }
                        
                        if card.cardType == .flashcard {
                            flashcardAnswerView()
                                .onAppear {
                                    if isSelected && selectedCardModel.isNewlyCreated {
                                        showingFlashcardAnswer = true
                                    }
                                }
                                .onChange(of: isSelected) { _, newValue in
                                    if card.cardType == .flashcard && newValue && selectedCardModel.isNewlyCreated {
                                        showingFlashcardAnswer = true
                                    }
                                }
                                .onChange(of: selectedCardModel.isNewlyCreated) { _, newValue in
                                    if card.cardType == .flashcard && isSelected && newValue {
                                        showingFlashcardAnswer = true
                                    }
                                }
                            if isSelected {
                                TagInputView(card: card)
                                .padding(.vertical, 4)
                        }
                        }
                    } else {
                        Text(card.displayContent)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(isArchived ? .gray : .primary)
                            .strikethrough(card.cardType == .todo && card.isComplete, color: .gray)
   
                    }

                    // New section for inline settings and controls when selected
                    if isSelected {
                        VStack(alignment: .leading, spacing: 10) {
                            
                            FolderMenu(card: card, folders: folders)
                        
                            HStack{
                                Spacer()
                                RecurringButton(isRecurring: card.isRecurring, action: { 
                                    card.isRecurring.toggle()
                                    if !card.isRecurring {
                                        Task { await RecurringOffTip.toggledRecurringOffEvent.donate() }
                                    }
                                })
                                .popoverTip(recurringOffTip, arrowEdge: .bottom)
                                Spacer()
                                PriorityMenu(selected: Binding(
                                    get: { card.priority },
                                    set: { card.priority = $0 }
                                ))
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
                                policiesMenu()
                                .popoverTip(policiesTip, arrowEdge: .top)
                                .onAppear {
                                    if isSelected {
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
            }


            
            if !isSelected {
                cardFolderAndTagsView()
                    .padding(.top, 4)
            }
            
            
            VStack(alignment: .trailing) {
                seenAndSkipCountDisplay()
                if !card.isRecurring, !card.displayedRecurringMessageShort.isEmpty {
                    recurringMessageInfo()
                    
                }
               
            }
            .padding(2)
       
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
            CardRowSwipeLeft(card: card, showDetails: { activeSheet = .details }, moveAction: { activeSheet = .move })
        }
        .contextMenu {
            CardRowContextMenu(
                card: card,
                showDetails: { activeSheet = .details },
                moveAction: { activeSheet = .move },
                tagAction: { activeSheet = .tags }
            )
        }
        // Auto-delete when not selected and content is empty
        .onChange(of: isSelected) { _, newValue in
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
        .onAppear {
            deleteIfEmptyAndNotSelected()
        }
    }
}



// Recurring icon button - refactored to match policiesMenu style
fileprivate struct RecurringButton: View {
    var isRecurring: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "repeat")
                    .foregroundColor(isRecurring ? .white : .secondary)
                Text("Recurring")
                    .foregroundColor(isRecurring ? .white : .primary)
            }
            .font(.subheadline)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                Group {
                    if isRecurring {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.accentColor)
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary, lineWidth: 1.4)
                    }
                }
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}



// New helper view for IntervalMenu - matching policiesMenu style
fileprivate struct IntervalMenu: View {
    @Binding var selected: RepeatInterval
    var isRecurring: Bool
    var currentHours: Int // Current actual interval in hours
    
    // Compute display text from actual hours
    private var displayText: String {
        // Check if current hours match a predefined interval
        if let matchingInterval = RepeatInterval.allCases.first(where: { $0.hours == currentHours }) {
            return matchingInterval.rawValue
        }
        
        // Otherwise show the actual interval value
        if currentHours < 48 {
            return "\(currentHours)h"
        } else if currentHours < 168 {
            let days = currentHours / 24
            return "\(days)d"
        } else if currentHours < 720 {
            let weeks = currentHours / 168
            return "\(weeks)w"
        } else {
            let months = currentHours / 720
            return "\(months)mo"
        }
    }
    
    var body: some View {
        Menu {
            ForEach(RepeatInterval.allCases.filter { $0.hours != nil }, id: \.self) { interval in
                Button(action: { selected = interval }) {
                    Text(interval.rawValue)
                    if selected == interval {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .foregroundColor(isRecurring ? .primary : .secondary)
                Text(displayText)
                    .foregroundColor(isRecurring ? .primary : .secondary)
            }
            .font(.subheadline)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.5))
            )
            .contentShape(Rectangle())
        }
    }
}

fileprivate struct PriorityMenu: View {
    @Binding var selected: PriorityType
    
    private func next(after current: PriorityType) -> PriorityType {
        switch current {
        case .none: return .low
        case .low: return .med
        case .med: return .high
        case .high: return .none
        }
    }
    
    var body: some View {
        Button {
            selected = next(after: selected)
        } label: {
            HStack(spacing: 4) {
                switch selected {
                case .none:
                    Image(systemName: "flag" )
                        .foregroundColor(.primary)
                    Image(systemName: "flag" )
                        .foregroundColor(.primary)
                    Image(systemName: "flag" )
                        .foregroundColor(.primary)
                case .low:
                    Image(systemName: "flag.fill")
                        .foregroundColor(.primary)
                    Image(systemName: "flag" )
                        .foregroundColor(.primary)
                    Image(systemName: "flag" )
                        .foregroundColor(.primary)
                case .med:
                    Image(systemName: "flag.fill")
                        .foregroundColor(.primary)
                    Image(systemName: "flag.fill" )
                        .foregroundColor(.primary)
                    Image(systemName: "flag" )
                        .foregroundColor(.primary)
                case .high:
                    Image(systemName: "flag.fill")
                        .foregroundColor(.primary)
                    Image(systemName: "flag.fill" )
                        .foregroundColor(.primary)
                    Image(systemName: "flag.fill" )
                        .foregroundColor(.primary)
                }
            }
            .font(.subheadline)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.5))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

