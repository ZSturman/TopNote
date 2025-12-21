//
//  AICardGeneratorSheet.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/20/25.
//

import SwiftUI
import SwiftData

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - AI Card Generator Sheet (iOS 26+)

@available(iOS 26.0, macOS 26.0, *)
struct AICardGeneratorSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query var folders: [Folder]
    @Query var allTags: [CardTag]
    
    let currentFolder: Folder?
    let currentTagIDs: [UUID]
    let onCardsCreated: ([Card]) -> Void
    
    // Generation settings
    @State private var topic: String = ""
    @State private var generateNotes: Bool = true
    @State private var generateTodos: Bool = false
    @State private var generateFlashcards: Bool = false
    @State private var cardCount: Int = 3
    @State private var styleHint: String = ""
    
    // Organization
    @State private var selectedFolder: Folder?
    @State private var selectedTags: [CardTag] = []
    
    // Per-card-type options expansion state
    @State private var notesOptionsExpanded: Bool = false
    @State private var todosOptionsExpanded: Bool = false
    @State private var flashcardsOptionsExpanded: Bool = false
    
    // Notes card options
    @State private var notesPriority: PriorityType = .none
    @State private var notesIsRecurring: Bool = true
    @State private var notesRepeatInterval: RepeatInterval = .every4Months
    @State private var notesSkipEnabled: Bool = true
    @State private var notesSkipPolicy: RepeatPolicy = .mild
    
    // Todos card options
    @State private var todosPriority: PriorityType = .none
    @State private var todosIsRecurring: Bool = true
    @State private var todosRepeatInterval: RepeatInterval = .monthly
    @State private var todosSkipEnabled: Bool = true
    @State private var todosSkipPolicy: RepeatPolicy = .aggressive
    @State private var todosResetRepeatIntervalOnComplete: Bool = true
    
    // Flashcards card options
    @State private var flashcardsPriority: PriorityType = .none
    @State private var flashcardsIsRecurring: Bool = true
    @State private var flashcardsRepeatInterval: RepeatInterval = .every2Months
    @State private var flashcardsSkipEnabled: Bool = false
    @State private var flashcardsSkipPolicy: RepeatPolicy = .none
    @State private var flashcardsRatingEasyPolicy: RepeatPolicy = .mild
    @State private var flashcardsRatingMedPolicy: RepeatPolicy = .none
    @State private var flashcardsRatingHardPolicy: RepeatPolicy = .aggressive
    
    // Generation state
    @State private var isGenerating: Bool = false
    @State private var generatedCards: [GeneratedCardFallback] = []
    @State private var errorMessage: String? = nil
    @State private var hasGenerated: Bool = false
    
    // Edit state
    @State private var editingCardID: UUID? = nil
    @State private var editContent: String = ""
    @State private var editAnswer: String = ""
    
    // Focus state for keyboard dismissal
    @FocusState private var isTopicFocused: Bool
    @FocusState private var isStyleHintFocused: Bool
    
    private var selectedCardTypes: [String] {
        var types: [String] = []
        if generateNotes { types.append("note") }
        if generateTodos { types.append("todo") }
        if generateFlashcards { types.append("flashcard") }
        return types
    }
    
    private var canGenerate: Bool {
        !topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedCardTypes.isEmpty &&
        !isGenerating
    }
    
    // Scroll state
    @State private var scrollToGeneratedCards: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    // MARK: - Topic Section
                    Section {
                        TextField("e.g., Spanish vocabulary, Project tasks, Study notes...", text: $topic, axis: .vertical)
                            .lineLimit(2...4)
                            .textFieldStyle(.plain)
                            .focused($isTopicFocused)
                    } header: {
                        Text("Topic or Subject")
                    } footer: {
                        Text("Describe what you want to create cards about. Be specific for better results.")
                    }
                
                // MARK: - Card Types Section
                Section {
                    // Notes toggle with expandable settings
                    Toggle(isOn: $generateNotes) {
                        Label("Notes", systemImage: "doc.text")
                    }
                    .tint(.yellow)
                    
                    if generateNotes {
                        Button {
                            withAnimation {
                                notesOptionsExpanded.toggle()
                            }
                        } label: {
                            HStack {
                                Label("Notes Settings", systemImage: "gearshape")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Image(systemName: notesOptionsExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        if notesOptionsExpanded {
                            CardOptionsSection(
                                cardType: .note,
                                priority: $notesPriority,
                                isRecurring: $notesIsRecurring,
                                repeatInterval: $notesRepeatInterval,
                                skipEnabled: $notesSkipEnabled,
                                skipPolicy: $notesSkipPolicy,
                                resetRepeatIntervalOnComplete: .constant(false),
                                ratingEasyPolicy: .constant(.mild),
                                ratingMedPolicy: .constant(.none),
                                ratingHardPolicy: .constant(.aggressive)
                            )
                        }
                    }
                    
                    // Todos toggle with expandable settings
                    Toggle(isOn: $generateTodos) {
                        Label("To-dos", systemImage: "checklist")
                    }
                    .tint(.green)
                    
                    if generateTodos {
                        Button {
                            withAnimation {
                                todosOptionsExpanded.toggle()
                            }
                        } label: {
                            HStack {
                                Label("To-do Settings", systemImage: "gearshape")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Image(systemName: todosOptionsExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        if todosOptionsExpanded {
                            CardOptionsSection(
                                cardType: .todo,
                                priority: $todosPriority,
                                isRecurring: $todosIsRecurring,
                                repeatInterval: $todosRepeatInterval,
                                skipEnabled: $todosSkipEnabled,
                                skipPolicy: $todosSkipPolicy,
                                resetRepeatIntervalOnComplete: $todosResetRepeatIntervalOnComplete,
                                ratingEasyPolicy: .constant(.mild),
                                ratingMedPolicy: .constant(.none),
                                ratingHardPolicy: .constant(.aggressive)
                            )
                        }
                    }
                    
                    // Flashcards toggle with expandable settings
                    Toggle(isOn: $generateFlashcards) {
                        Label("Flashcards", systemImage: "rectangle.on.rectangle.angled")
                    }
                    .tint(.blue)
                    
                    if generateFlashcards {
                        Button {
                            withAnimation {
                                flashcardsOptionsExpanded.toggle()
                            }
                        } label: {
                            HStack {
                                Label("Flashcard Settings", systemImage: "gearshape")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Image(systemName: flashcardsOptionsExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        if flashcardsOptionsExpanded {
                            CardOptionsSection(
                                cardType: .flashcard,
                                priority: $flashcardsPriority,
                                isRecurring: $flashcardsIsRecurring,
                                repeatInterval: $flashcardsRepeatInterval,
                                skipEnabled: $flashcardsSkipEnabled,
                                skipPolicy: $flashcardsSkipPolicy,
                                resetRepeatIntervalOnComplete: .constant(false),
                                ratingEasyPolicy: $flashcardsRatingEasyPolicy,
                                ratingMedPolicy: $flashcardsRatingMedPolicy,
                                ratingHardPolicy: $flashcardsRatingHardPolicy
                            )
                        }
                    }
                } header: {
                    Text("Card Types to Generate")
                } footer: {
                    if selectedCardTypes.isEmpty {
                        Text("Select at least one card type")
                            .foregroundStyle(.red)
                    }
                }
                
                // MARK: - Count Section
                Section {
                    Stepper("Generate \(cardCount) card\(cardCount == 1 ? "" : "s")", value: $cardCount, in: 1...5)
                } header: {
                    Text("Number of Cards")
                } footer: {
                    Text("Generate 1-5 cards at a time for best results.")
                }
                
                // MARK: - Optional Style Hint
                Section {
                    TextField("e.g., Keep it simple, Use formal language...", text: $styleHint, axis: .vertical)
                        .lineLimit(1...2)
                        .textFieldStyle(.plain)
                        .focused($isStyleHintFocused)
                } header: {
                    Text("Style Hint (Optional)")
                } footer: {
                    Text("Add any specific style or formatting preferences.")
                }
                
                // MARK: - Organization Section
                Section {
                    Picker("Folder", selection: $selectedFolder) {
                        Text("No folder").tag(nil as Folder?)
                        ForEach(folders.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { folder in
                            Text(folder.name).tag(folder as Folder?)
                        }
                    }
                } header: {
                    Text("Save To")
                }
                
                // MARK: - Generate Button
                Section {
                    Button {
                        generateCards()
                    } label: {
                        HStack {
                            Spacer()
                            if isGenerating {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Generating...")
                            } else {
                                Label("Generate Cards with AI", systemImage: "sparkles")
                            }
                            Spacer()
                        }
                        .font(.headline)
                        .padding(.vertical, 4)
                    }
                    .disabled(!canGenerate)
                    
                    // Error message
                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Button("Try Again") {
                            errorMessage = nil
                            generateCards()
                        }
                        .font(.subheadline)
                    }
                }
                
                // MARK: - Generated Cards Preview
                if hasGenerated && !generatedCards.isEmpty {
                    Section {
                        ForEach($generatedCards) { $card in
                            GeneratedCardRow(
                                card: $card,
                                isEditing: editingCardID == card.id,
                                editContent: $editContent,
                                editAnswer: $editAnswer,
                                onEdit: {
                                    editingCardID = card.id
                                    editContent = card.content
                                    editAnswer = card.answer ?? ""
                                },
                                onSaveEdit: {
                                    saveEdit(for: card)
                                },
                                onCancelEdit: {
                                    editingCardID = nil
                                },
                                onDelete: {
                                    deleteCard(card)
                                }
                            )
                        }
                    } header: {
                        HStack {
                            Text("Generated Cards")
                            Spacer()
                            Text("\(generatedCards.count) card\(generatedCards.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .id("generatedCardsSection")
                    } footer: {
                        Text("Review and edit cards before saving. Tap a card to edit.")
                    }
                    
                    // Save All Button
                    Section {
                        Button {
                            saveAllCards()
                        } label: {
                            HStack {
                                Spacer()
                                Label("Save \(generatedCards.count) Card\(generatedCards.count == 1 ? "" : "s")", systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .disabled(generatedCards.isEmpty)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: scrollToGeneratedCards) { _, shouldScroll in
                if shouldScroll {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo("generatedCardsSection", anchor: .top)
                    }
                    scrollToGeneratedCards = false
                }
            }
            .navigationTitle("Generate with AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                selectedFolder = currentFolder
                selectedTags = allTags.filter { currentTagIDs.contains($0.id) }
            }
            } // End ScrollViewReader
        } // End NavigationStack
    } // End body
    
    // MARK: - Generation Logic
    
    private func generateCards() {
        // Dismiss keyboard
        isTopicFocused = false
        isStyleHintFocused = false
        
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                #if canImport(FoundationModels)
                let session = LanguageModelSession()
                
                let typesDescription = selectedCardTypes.joined(separator: ", ")
                let styleInstruction = styleHint.isEmpty ? "" : " Style: \(styleHint)."
                
                let prompt = """
                Generate exactly \(cardCount) cards about: \(topic)
                
                Card types to include: \(typesDescription)
                \(styleInstruction)
                
                Requirements:
                - Each card's content must be under 150 characters (suitable for a widget)
                - For flashcards, the answer must be under 100 characters
                - Make content clear, concise, and actionable
                - Distribute evenly among the requested card types if multiple are selected
                - For todos: make them actionable tasks
                - For notes: make them informative snippets
                - For flashcards: create question/answer pairs
                """
                
                let response = try await session.respond(
                    to: prompt,
                    generating: GeneratedCardBatch.self
                )
                
                // Access the generated content from the response
                let generatedBatch = response.content
                let cards = generatedBatch.cards.filter { $0.isValid }.map { generated -> GeneratedCardFallback in
                    var card = GeneratedCardFallback(
                        cardType: generated.cardType,
                        content: generated.cleanedContent,
                        answer: generated.cleanedAnswer
                    )
                    // Apply type-specific defaults from user settings
                    switch card.resolvedCardType {
                    case .note:
                        card.priority = self.notesPriority
                        card.isRecurring = self.notesIsRecurring
                        card.repeatInterval = self.notesRepeatInterval
                        card.skipEnabled = self.notesSkipEnabled
                        card.skipPolicy = self.notesSkipPolicy
                    case .todo:
                        card.priority = self.todosPriority
                        card.isRecurring = self.todosIsRecurring
                        card.repeatInterval = self.todosRepeatInterval
                        card.skipEnabled = self.todosSkipEnabled
                        card.skipPolicy = self.todosSkipPolicy
                        card.resetRepeatIntervalOnComplete = self.todosResetRepeatIntervalOnComplete
                    case .flashcard:
                        card.priority = self.flashcardsPriority
                        card.isRecurring = self.flashcardsIsRecurring
                        card.repeatInterval = self.flashcardsRepeatInterval
                        card.skipEnabled = self.flashcardsSkipEnabled
                        card.skipPolicy = self.flashcardsSkipPolicy
                        card.ratingEasyPolicy = self.flashcardsRatingEasyPolicy
                        card.ratingMedPolicy = self.flashcardsRatingMedPolicy
                        card.ratingHardPolicy = self.flashcardsRatingHardPolicy
                    }
                    return card
                }
                
                await MainActor.run {
                    generatedCards = cards
                    hasGenerated = true
                    isGenerating = false
                    
                    if cards.isEmpty {
                        errorMessage = "No valid cards were generated. Try a different topic."
                    } else {
                        // Scroll to generated cards section after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            scrollToGeneratedCards = true
                        }
                    }
                }
                #else
                await MainActor.run {
                    errorMessage = "AI generation requires iOS 26 or later with Apple Intelligence."
                    isGenerating = false
                }
                #endif
            } catch {
                await MainActor.run {
                    if error.localizedDescription.contains("not supported") ||
                       error.localizedDescription.contains("unavailable") {
                        errorMessage = "Apple Intelligence is not available on this device. Make sure you have an Apple Silicon Mac or compatible iPhone."
                    } else {
                        errorMessage = "Generation failed: \(error.localizedDescription)"
                    }
                    isGenerating = false
                }
            }
        }
    }
    
    private func saveEdit(for card: GeneratedCardFallback) {
        if let index = generatedCards.firstIndex(where: { $0.id == card.id }) {
            var updatedCard = generatedCards[index]
            updatedCard.content = editContent
            if card.resolvedCardType == .flashcard {
                updatedCard.answer = editAnswer
            }
            generatedCards[index] = updatedCard
        }
        editingCardID = nil
    }
    
    private func deleteCard(_ card: GeneratedCardFallback) {
        generatedCards.removeAll { $0.id == card.id }
    }
    
    private func saveAllCards() {
        var createdCards: [Card] = []
        
        // Set nextTimeInQueue to 1 hour in the future (same as NewCardSheet)
        let nextTimeInQueueForNewCard = Date().addingTimeInterval(3600)
        
        for generated in generatedCards {
            // Get the resolved card type
            let cardType = generated.resolvedCardType
            
            // Use the per-card options directly from the generated card
            let card = createCard(
                in: modelContext,
                cardType: cardType,
                content: generated.cleanedContent,
                answer: generated.cleanedAnswer,
                folder: selectedFolder,
                tags: selectedTags,
                isRecurring: generated.isRecurring,
                priority: generated.priority,
                repeatInterval: generated.repeatInterval.hours ?? 240,
                nextTimeInQueue: nextTimeInQueueForNewCard,
                skipEnabled: generated.skipEnabled,
                skipPolicy: generated.skipPolicy,
                resetRepeatIntervalOnComplete: generated.resetRepeatIntervalOnComplete,
                ratingEasyPolicy: generated.ratingEasyPolicy,
                ratingMedPolicy: generated.ratingMedPolicy,
                ratingHardPolicy: generated.ratingHardPolicy
            )
            createdCards.append(card)
        }
        
        do {
            try modelContext.save()
            onCardsCreated(createdCards)
            dismiss()
        } catch {
            errorMessage = "Failed to save cards: \(error.localizedDescription)"
        }
    }
}

// MARK: - Generated Card Row

private struct GeneratedCardRow: View {
    @Binding var card: GeneratedCardFallback
    let isEditing: Bool
    @Binding var editContent: String
    @Binding var editAnswer: String
    let onEdit: () -> Void
    let onSaveEdit: () -> Void
    let onCancelEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Card type badge
            HStack {
                Label(card.resolvedCardType.rawValue, systemImage: card.resolvedCardType.systemImage)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(card.resolvedCardType.tintColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(card.resolvedCardType.tintColor.opacity(0.15))
                    .clipShape(Capsule())
                
                Spacer()
                
                if !isEditing {
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                }
            }
            
            if isEditing {
                // Edit mode
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    TextEditor(text: $editContent)
                        .font(.subheadline)
                        .frame(minHeight: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                    
                    if card.resolvedCardType == .flashcard {
                        Text("Answer")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        TextEditor(text: $editAnswer)
                            .font(.subheadline)
                            .frame(minHeight: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // MARK: - Inline Controls (Recurring, Priority, Interval, Policies)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Card Settings")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 8) {
                            // Recurring Button
                            Button {
                                card.isRecurring.toggle()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "repeat")
                                        .foregroundColor(card.isRecurring ? .white : .secondary)
                                }
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(
                                    Group {
                                        if card.isRecurring {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.accentColor)
                                        } else {
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.secondary, lineWidth: 1.4)
                                        }
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                            
                            // Priority Button
                            Button {
                                card.priority = nextPriority(after: card.priority)
                            } label: {
                                HStack(spacing: 2) {
                                    priorityIcon(for: card.priority)
                                }
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.secondary.opacity(0.5))
                                )
                            }
                            .buttonStyle(.plain)
                            
                            // Interval Menu
                            Menu {
                                ForEach(RepeatInterval.allCases.filter { $0.hours != nil }, id: \.self) { interval in
                                    Button(action: { card.repeatInterval = interval }) {
                                        Text(interval.rawValue)
                                        if card.repeatInterval == interval {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                        .foregroundColor(card.isRecurring ? .primary : .secondary)
                                    Text(card.repeatInterval.rawValue)
                                        .foregroundColor(card.isRecurring ? .primary : .secondary)
                                }
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.secondary.opacity(0.5))
                                )
                            }
                            
                            // Policies Menu
                            Menu {
                                if card.resolvedCardType == .todo {
                                    Toggle(isOn: $card.resetRepeatIntervalOnComplete) {
                                        Label("Reset Interval On Complete", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                                    }
                                    Divider()
                                }
                                
                                Menu {
                                    Toggle(isOn: $card.skipEnabled) {
                                        Label("Enable Skip", systemImage: "arrow.trianglehead.counterclockwise.rotate.90")
                                    }
                                    
                                    if card.skipEnabled {
                                        Picker("On Skip", selection: $card.skipPolicy) {
                                            ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                                                Text(policy.rawValue).tag(policy)
                                            }
                                        }
                                        .pickerStyle(.inline)
                                    }
                                } label: {
                                    HStack {
                                        Text("On Skip:")
                                        Text(card.skipPolicy.rawValue)
                                            .fontWeight(.semibold)
                                    }
                                }
                                
                                if card.resolvedCardType == .flashcard {
                                    Divider()
                                    
                                    Picker("On Easy", selection: $card.ratingEasyPolicy) {
                                        ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                                            Text(policy.rawValue).tag(policy)
                                        }
                                    }
                                    
                                    Picker("On Good", selection: $card.ratingMedPolicy) {
                                        ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                                            Text(policy.rawValue).tag(policy)
                                        }
                                    }
                                    
                                    Picker("On Hard", selection: $card.ratingHardPolicy) {
                                        ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                                            Text(policy.rawValue).tag(policy)
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.secondary.opacity(0.5))
                                    )
                            }
                        }
                    }
                    .padding(.top, 4)
                    
                    HStack {
                        Button("Cancel") {
                            onCancelEdit()
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button("Save") {
                            onSaveEdit()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                // Display mode
                Text(card.content)
                    .font(.subheadline)
                
                if let answer = card.answer, !answer.isEmpty, card.resolvedCardType == .flashcard {
                    Divider()
                    HStack {
                        Text("Answer:")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        Text(answer)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func nextPriority(after current: PriorityType) -> PriorityType {
        switch current {
        case .none: return .low
        case .low: return .med
        case .med: return .high
        case .high: return .none
        }
    }
    
    @ViewBuilder
    private func priorityIcon(for priority: PriorityType) -> some View {
        switch priority {
        case .none:
            Image(systemName: "flag")
                .foregroundColor(.primary)
            Image(systemName: "flag")
                .foregroundColor(.primary)
            Image(systemName: "flag")
                .foregroundColor(.primary)
        case .low:
            Image(systemName: "flag.fill")
                .foregroundColor(.primary)
            Image(systemName: "flag")
                .foregroundColor(.primary)
            Image(systemName: "flag")
                .foregroundColor(.primary)
        case .med:
            Image(systemName: "flag.fill")
                .foregroundColor(.primary)
            Image(systemName: "flag.fill")
                .foregroundColor(.primary)
            Image(systemName: "flag")
                .foregroundColor(.primary)
        case .high:
            Image(systemName: "flag.fill")
                .foregroundColor(.primary)
            Image(systemName: "flag.fill")
                .foregroundColor(.primary)
            Image(systemName: "flag.fill")
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Availability Wrapper

/// A view that checks for AI availability and shows appropriate UI
struct AICardGeneratorWrapper: View {
    let currentFolder: Folder?
    let currentTagIDs: [UUID]
    let onCardsCreated: ([Card]) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            AICardGeneratorSheet(
                currentFolder: currentFolder,
                currentTagIDs: currentTagIDs,
                onCardsCreated: onCardsCreated
            )
        } else {
            // Fallback for older iOS versions
            NavigationStack {
                VStack(spacing: 20) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    
                    Text("AI Generation Unavailable")
                        .font(.title2.weight(.semibold))
                    
                    Text("AI card generation requires iOS 26 or later with Apple Intelligence support.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .navigationTitle("Generate with AI")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    if #available(iOS 26.0, macOS 26.0, *) {
        AICardGeneratorSheet(
            currentFolder: nil,
            currentTagIDs: [],
            onCardsCreated: { _ in }
        )
    }
}
