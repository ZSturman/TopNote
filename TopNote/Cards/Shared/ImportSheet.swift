//
//  ImportSheet.swift
//  TopNote
//
//  Created by Zachary Sturman on 1/3/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @Query private var folders: [Folder]
    
    // Import state
    @State private var importFormat: ImportFormat = .json
    @State private var showImportPicker: Bool = false
    @State private var isImporting: Bool = false
    @State private var importResult: ImportResult? = nil
    
    // Override settings toggle
    @State private var useOverrideSettings: Bool = false
    
    // Folder override
    @State private var overrideFolder: Folder? = nil
    
    // Per-card-type settings expansion
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
    
    enum ImportFormat: String, CaseIterable, Identifiable {
        case json = "JSON"
        case csv = "CSV"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .json:
                return "Import cards exported from TopNote or matching the TopNote format."
            case .csv:
                return "Import cards from a spreadsheet. First row should be headers."
            }
        }
        
        var icon: String {
            switch self {
            case .json: return "doc.badge.gearshape"
            case .csv: return "tablecells"
            }
        }
        
        var contentType: UTType {
            switch self {
            case .json: return .json
            case .csv: return .commaSeparatedText
            }
        }
    }
    
    enum ImportResult {
        case success(count: Int)
        case error(message: String)
    }
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Format Selection
                Section {
                    ForEach(ImportFormat.allCases) { format in
                        Button {
                            importFormat = format
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: format.icon)
                                    .font(.title2)
                                    .foregroundStyle(importFormat == format ? Color.accentColor : Color.secondary)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(format.rawValue)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        
                                        if importFormat == format {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.tint)
                                        }
                                    }
                                    
                                    Text(format.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("File Format")
                }
                
                // MARK: - Override Settings Toggle
                Section {
                    Toggle(isOn: $useOverrideSettings) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Apply Custom Settings")
                            Text("Override imported card settings with your preferences")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("When enabled, your settings below will override any settings in the imported file. When disabled, the file's settings will be used.")
                }
                
                // MARK: - Override Settings (when enabled)
                if useOverrideSettings {
                    // Folder Override
                    Section {
                        Picker("Folder", selection: $overrideFolder) {
                            Text("Use file setting").tag(nil as Folder?)
                            Divider()
                            ForEach(folders.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { folder in
                                Text(folder.name).tag(folder as Folder?)
                            }
                        }
                    } header: {
                        Text("Folder")
                    }
                    
                    // Notes Settings
                    Section {
                        Button {
                            withAnimation {
                                notesOptionsExpanded.toggle()
                            }
                        } label: {
                            HStack {
                                Image(systemName: CardType.note.systemImage)
                                    .foregroundColor(CardType.note.tintColor)
                                Text("Note Settings")
                                    .foregroundStyle(.primary)
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
                    
                    // Todos Settings
                    Section {
                        Button {
                            withAnimation {
                                todosOptionsExpanded.toggle()
                            }
                        } label: {
                            HStack {
                                Image(systemName: CardType.todo.systemImage)
                                    .foregroundColor(CardType.todo.tintColor)
                                Text("Todo Settings")
                                    .foregroundStyle(.primary)
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
                    
                    // Flashcards Settings
                    Section {
                        Button {
                            withAnimation {
                                flashcardsOptionsExpanded.toggle()
                            }
                        } label: {
                            HStack {
                                Image(systemName: CardType.flashcard.systemImage)
                                    .foregroundColor(CardType.flashcard.tintColor)
                                Text("Flashcard Settings")
                                    .foregroundStyle(.primary)
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
                }
                
                // MARK: - Import Action
                Section {
                    Button {
                        showImportPicker = true
                    } label: {
                        HStack {
                            Spacer()
                            if isImporting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Label("Select File to Import", systemImage: "square.and.arrow.down")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .disabled(isImporting)
                    
                    // Import result feedback
                    if let result = importResult {
                        switch result {
                        case .success(let count):
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Successfully imported \(count) cards")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        case .error(let message):
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text(message)
                                    .font(.subheadline)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                } footer: {
                    Text("Imported cards will be added to your collection. Existing cards won't be duplicated if they have matching creation dates and content.")
                }
            }
            .navigationTitle("Import Cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [importFormat.contentType]
            ) { result in
                handleImport(result)
            }
        }
    }
    
    // MARK: - Import Logic
    
    private func handleImport(_ result: Result<URL, Error>) {
        isImporting = true
        importResult = nil
        
        switch result {
        case .success(let url):
            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                importResult = .error(message: "Could not access the selected file")
                isImporting = false
                return
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                var importedCount = 0
                let overrides = buildOverrides()
                
                switch importFormat {
                case .json:
                    let data = try Data(contentsOf: url)
                    if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                        for dict in jsonArray {
                            if let card = CardImport.makeCard(from: dict, context: context, overrides: useOverrideSettings ? overrides : nil) {
                                context.insert(card)
                                importedCount += 1
                            }
                        }
                    }
                    
                case .csv:
                    let csvString = try String(contentsOf: url, encoding: .utf8)
                    let cards = try CardImport.parseCSV(csvString, context: context, overrides: useOverrideSettings ? overrides : nil)
                    for card in cards {
                        context.insert(card)
                        importedCount += 1
                    }
                }
                
                try context.save()
                importResult = .success(count: importedCount)
                
            } catch {
                importResult = .error(message: "Import failed: \(error.localizedDescription)")
            }
            
        case .failure(let error):
            importResult = .error(message: "Could not open file: \(error.localizedDescription)")
        }
        
        isImporting = false
    }
    
    private func buildOverrides() -> CardImportOverrides {
        CardImportOverrides(
            folder: overrideFolder,
            noteSettings: CardTypeImportSettings(
                priority: notesPriority,
                isRecurring: notesIsRecurring,
                repeatInterval: notesRepeatInterval.hours ?? 2880,
                skipEnabled: notesSkipEnabled,
                skipPolicy: notesSkipPolicy,
                resetRepeatIntervalOnComplete: false,
                ratingEasyPolicy: .mild,
                ratingMedPolicy: .none,
                ratingHardPolicy: .aggressive
            ),
            todoSettings: CardTypeImportSettings(
                priority: todosPriority,
                isRecurring: todosIsRecurring,
                repeatInterval: todosRepeatInterval.hours ?? 720,
                skipEnabled: todosSkipEnabled,
                skipPolicy: todosSkipPolicy,
                resetRepeatIntervalOnComplete: todosResetRepeatIntervalOnComplete,
                ratingEasyPolicy: .mild,
                ratingMedPolicy: .none,
                ratingHardPolicy: .aggressive
            ),
            flashcardSettings: CardTypeImportSettings(
                priority: flashcardsPriority,
                isRecurring: flashcardsIsRecurring,
                repeatInterval: flashcardsRepeatInterval.hours ?? 1440,
                skipEnabled: flashcardsSkipEnabled,
                skipPolicy: flashcardsSkipPolicy,
                resetRepeatIntervalOnComplete: false,
                ratingEasyPolicy: flashcardsRatingEasyPolicy,
                ratingMedPolicy: flashcardsRatingMedPolicy,
                ratingHardPolicy: flashcardsRatingHardPolicy
            )
        )
    }
}

// MARK: - Import Override Models

struct CardImportOverrides {
    let folder: Folder?
    let noteSettings: CardTypeImportSettings
    let todoSettings: CardTypeImportSettings
    let flashcardSettings: CardTypeImportSettings
    
    func settings(for cardType: CardType) -> CardTypeImportSettings {
        switch cardType {
        case .note: return noteSettings
        case .todo: return todoSettings
        case .flashcard: return flashcardSettings
        }
    }
}

struct CardTypeImportSettings {
    let priority: PriorityType
    let isRecurring: Bool
    let repeatInterval: Int
    let skipEnabled: Bool
    let skipPolicy: RepeatPolicy
    let resetRepeatIntervalOnComplete: Bool
    let ratingEasyPolicy: RepeatPolicy
    let ratingMedPolicy: RepeatPolicy
    let ratingHardPolicy: RepeatPolicy
}

#Preview {
    ImportSheet()
}
