//
//  NewCardSheet.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/17/25.
//

import SwiftUI
import SwiftData
import os.log

struct NewCardSheet: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query var folders: [Folder]
    @Query var allTags: [CardTag]
    
    let cardType: CardType
    let currentFolder: Folder?
    let currentTagIDs: [UUID]
    let onSave: (Card) -> Void
    
    // Draft state for the new card
    @State private var content: String = ""
    @State private var answer: String = ""
    @State private var selectedFolder: Folder?
    @State private var selectedTags: [CardTag] = []
    @State private var priority: PriorityType = .none
    @State private var isRecurring: Bool = true
    @State private var repeatInterval: RepeatInterval = .every10Days
    @State private var skipEnabled: Bool = true
    @State private var skipPolicy: RepeatPolicy = .none
    @State private var resetRepeatIntervalOnComplete: Bool = true
    @State private var ratingEasyPolicy: RepeatPolicy = .mild
    @State private var ratingMedPolicy: RepeatPolicy = .none
    @State private var ratingHardPolicy: RepeatPolicy = .aggressive
    
    // UI state
    @State private var showingFlashcardAnswer: Bool = false
    @State private var newTagText: String = ""
    @State private var showAIGenerator: Bool = false
    @State private var showNewFolderSheet: Bool = false
    @State private var newFolderName: String = ""
    @FocusState private var isContentFocused: Bool
    @FocusState private var isAnswerFocused: Bool
    
    /// Placeholder text based on card type
    private var contentPlaceholder: String {
        switch cardType {
        case .note:
            return "Enter your note..."
        case .todo:
            return "Enter your task..."
        case .flashcard:
            return "Enter your question..."
        }
    }
    
    init(
        cardType: CardType,
        currentFolder: Folder?,
        currentTagIDs: [UUID],
        onSave: @escaping (Card) -> Void
    ) {
        self.cardType = cardType
        self.currentFolder = currentFolder
        self.currentTagIDs = currentTagIDs
        self.onSave = onSave
        
        // Set type-specific defaults
        switch cardType {
        case .flashcard:
            _skipEnabled = State(initialValue: false)
            _skipPolicy = State(initialValue: .none)
            _resetRepeatIntervalOnComplete = State(initialValue: false)
            _repeatInterval = State(initialValue: .every2Months)
        case .todo:
            _skipEnabled = State(initialValue: true)
            _skipPolicy = State(initialValue: .aggressive)
            _resetRepeatIntervalOnComplete = State(initialValue: true)
            _repeatInterval = State(initialValue: .monthly)
        case .note:
            _skipEnabled = State(initialValue: true)
            _skipPolicy = State(initialValue: .mild)
            _resetRepeatIntervalOnComplete = State(initialValue: false)
            _repeatInterval = State(initialValue: .every4Months)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - AI Generation Section
                if #available(iOS 26.0, *) {
                    Section {
                        Button {
                            showAIGenerator = true
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.title2)
                                    .foregroundStyle(.purple)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Generate with AI")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("Create multiple cards using Apple Intelligence")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    } footer: {
                        Text("Use AI to quickly generate notes, to-dos, or flashcards based on a topic.")
                    }
                }
                
                // MARK: - Content Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        ZStack(alignment: .topLeading) {
                            if content.isEmpty {
                                Text(contentPlaceholder)
                                    .foregroundStyle(.secondary)
                                    .font(.headline.weight(.semibold))
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $content)
                                .font(.headline.weight(.semibold))
                                .frame(minHeight: 100, maxHeight: 200)
                                .focused($isContentFocused)
                                .accessibilityIdentifier("NewCard Content Editor")
                        }
                    }
                } header: {
                    Text("Content")
                }
                
                // MARK: - Answer Section (Flashcard only)
                if cardType == .flashcard {
                    Section {
                        if showingFlashcardAnswer {
                            ZStack(alignment: .topLeading) {
                                if answer.isEmpty {
                                    Text("Enter the answer...")
                                        .foregroundStyle(.secondary)
                                        .font(.subheadline)
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                        .allowsHitTesting(false)
                                }
                                TextEditor(text: $answer)
                                    .font(.subheadline)
                                    .frame(minHeight: 80, maxHeight: 150)
                                    .focused($isAnswerFocused)
                                    .accessibilityIdentifier("NewCard Answer Editor")
                            }
                            
                            Button("Hide Answer") {
                                withAnimation {
                                    showingFlashcardAnswer = false
                                }
                            }
                            .font(.subheadline)
                        } else {
                            Button("Show Answer") {
                                withAnimation {
                                    showingFlashcardAnswer = true
                                }
                            }
                            .font(.subheadline)
                        }
                    } header: {
                        Text("Answer")
                    }
                }
                
                // MARK: - Organization Section
                Section {
                    // Folder picker with New Folder option
                    VStack(alignment: .leading, spacing: 8) {
                        Menu {
                            Button(action: {
                                showNewFolderSheet = true
                            }) {
                                Label("New Folder...", systemImage: "folder.badge.plus")
                            }
                            Divider()
                            Button(action: {
                                selectedFolder = nil
                            }) {
                                HStack {
                                    Text("No Folder")
                                    if selectedFolder == nil {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            ForEach(folders.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { folder in
                                Button(action: {
                                    selectedFolder = folder
                                }) {
                                    HStack {
                                        Text(folder.name)
                                        if selectedFolder?.id == folder.id {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "folder")
                                    .foregroundStyle(.secondary)
                                Text(selectedFolder?.name ?? "No Folder")
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                    
                    // Tags
                    VStack(alignment: .leading, spacing: 12) {
                        // Tag input field with iOS-style design
                        HStack {
                            Image(systemName: "tag")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                            TextField("Add a tag...", text: $newTagText)
                                .textFieldStyle(.plain)
                                .font(.subheadline)
                                .onSubmit {
                                    addTag()
                                }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        
                        // Selected tags as pill chips
                        if !selectedTags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(selectedTags, id: \.id) { tag in
                                        HStack(spacing: 6) {
                                            Text(tag.name)
                                                .font(.subheadline)
                                            Button(action: { removeTag(tag) }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.accentColor.opacity(0.15))
                                        .foregroundStyle(Color.accentColor)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        
                        // Tag suggestions
                        let availableTags = allTags.filter { tag in
                            !selectedTags.contains(where: { $0.id == tag.id })
                        }
                        if !availableTags.isEmpty && !newTagText.isEmpty {
                            let filteredTags = availableTags.filter {
                                $0.name.lowercased().contains(newTagText.lowercased())
                            }
                            if !filteredTags.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(filteredTags.prefix(5)) { tag in
                                            Button {
                                                selectedTags.append(tag)
                                                newTagText = ""
                                            } label: {
                                                Text(tag.name)
                                                    .font(.subheadline)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color(.systemGray5))
                                                    .foregroundStyle(.primary)
                                                    .clipShape(Capsule())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text("Organization")
                }
                
                // MARK: - Schedule & Policies Sections
                CardOptionsSection(
                    cardType: cardType,
                    priority: $priority,
                    isRecurring: $isRecurring,
                    repeatInterval: $repeatInterval,
                    skipEnabled: $skipEnabled,
                    skipPolicy: $skipPolicy,
                    resetRepeatIntervalOnComplete: $resetRepeatIntervalOnComplete,
                    ratingEasyPolicy: $ratingEasyPolicy,
                    ratingMedPolicy: $ratingMedPolicy,
                    ratingHardPolicy: $ratingHardPolicy
                )
            }
            .navigationTitle("New \(cardType.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveCard()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                // Initialize from current context
                selectedFolder = currentFolder
                selectedTags = allTags.filter { currentTagIDs.contains($0.id) }
                
                // Auto-focus content field
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isContentFocused = true
                }
                
                // Auto-show answer for flashcards
                if cardType == .flashcard {
                    showingFlashcardAnswer = true
                }
            }
            .sheet(isPresented: $showAIGenerator) {
                AICardGeneratorWrapper(
                    currentFolder: selectedFolder,
                    currentTagIDs: selectedTags.map { $0.id },
                    onCardsCreated: { cards in
                        // Cards were created by AI, dismiss this sheet
                        dismiss()
                    }
                )
            }
            .sheet(isPresented: $showNewFolderSheet) {
                NewFolderSheetForCard(
                    folderName: $newFolderName,
                    onSave: { newFolder in
                        selectedFolder = newFolder
                        newFolderName = ""
                    }
                )
            }
        }
    }
    
    private func addTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Use centralized TagManager for consistent tag handling
        let tag = TagManager.getOrCreateTag(name: trimmed, context: modelContext)
        if !selectedTags.contains(where: { $0.id == tag.id }) {
            selectedTags.append(tag)
        }
        newTagText = ""
    }
    
    private func removeTag(_ tag: CardTag) {
        selectedTags.removeAll { $0.id == tag.id }
    }
    
    private func saveCard() {
        let now = Date()
        // Set nextTimeInQueue to 1 hour in the future so it appears in Upcoming
        let nextTimeInQueueForNewCard = now.addingTimeInterval(3600)
        
        let newCard = Card(
            createdAt: now,
            cardType: cardType,
            priorityTypeRaw: priority,
            content: content,
            isRecurring: isRecurring,
            skipCount: 0,
            seenCount: 0,
            repeatInterval: repeatInterval.hours ?? 240,
            initialRepeatInterval: repeatInterval.hours ?? 240,
            nextTimeInQueue: nextTimeInQueueForNewCard,
            folder: selectedFolder,
            tags: selectedTags,
            skipPolicy: skipPolicy,
            ratingEasyPolicy: ratingEasyPolicy,
            ratingMedPolicy: ratingMedPolicy,
            ratingHardPolicy: ratingHardPolicy,
            isComplete: false,
            resetRepeatIntervalOnComplete: resetRepeatIntervalOnComplete,
            skipEnabled: skipEnabled
        )
        
        // Set answer for flashcards
        if cardType == .flashcard && !answer.isEmpty {
            newCard.answer = answer
        }
        
        modelContext.insert(newCard)
        
        do {
            try modelContext.save()
            TopNoteLogger.cardMutation.info("Successfully created new card: \(newCard.id.uuidString), type: \(self.cardType.rawValue)")
        } catch {
            TopNoteLogger.cardMutation.error("Failed to save new card: \(error.localizedDescription)")
        }
        
        onSave(newCard)
        dismiss()
    }
}

// MARK: - New Folder Sheet for Card Creation
/// A compact sheet for creating a new folder during card creation
struct NewFolderSheetForCard: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingFolders: [Folder]
    
    @Binding var folderName: String
    let onSave: (Folder) -> Void
    
    @FocusState private var isFocused: Bool
    
    private var trimmedName: String {
        folderName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var isValid: Bool {
        !trimmedName.isEmpty && !existingFolders.contains { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }
    }
    
    private var errorMessage: String? {
        if trimmedName.isEmpty {
            return nil
        }
        if existingFolders.contains(where: { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }) {
            return "A folder with this name already exists"
        }
        return nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Folder name", text: $folderName)
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            if isValid {
                                createFolder()
                            }
                        }
                } header: {
                    Text("Name")
                } footer: {
                    if let error = errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        folderName = ""
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createFolder()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
        .presentationDetents([.height(200)])
        .presentationDragIndicator(.visible)
    }
    
    private func createFolder() {
        let newFolder = Folder(name: trimmedName)
        modelContext.insert(newFolder)
        do {
            try modelContext.save()
        } catch {
            // Handle error silently
        }
        onSave(newFolder)
        folderName = ""
        dismiss()
    }
}

// MARK: - New Tag Sheet for Batch Actions

struct NewTagSheetForBatch: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingTags: [CardTag]
    
    @Binding var tagName: String
    let onSave: (CardTag) -> Void
    
    @FocusState private var isFocused: Bool
    
    private var trimmedName: String {
        tagName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var isValid: Bool {
        !trimmedName.isEmpty && !existingTags.contains { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }
    }
    
    private var errorMessage: String? {
        if trimmedName.isEmpty {
            return nil
        }
        if existingTags.contains(where: { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }) {
            return "A tag with this name already exists"
        }
        return nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Tag name", text: $tagName)
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            if isValid {
                                createTag()
                            }
                        }
                } header: {
                    Text("Name")
                } footer: {
                    if let error = errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        tagName = ""
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createTag()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
        .presentationDetents([.height(200)])
        .presentationDragIndicator(.visible)
    }
    
    private func createTag() {
        let newTag = CardTag(name: trimmedName)
        modelContext.insert(newTag)
        do {
            try modelContext.save()
        } catch {
            // Handle error silently
        }
        onSave(newTag)
        tagName = ""
        dismiss()
    }
}
