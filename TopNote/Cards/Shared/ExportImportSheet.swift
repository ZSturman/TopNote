//
//  ExportImportSheet.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/20/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExportImportSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    let filteredCards: [Card]
    let allCards: [Card]
    
    // Export state
    @State private var exportFormat: ExportFormat = .json
    @State private var includeArchived: Bool = false
    @State private var isExporting: Bool = false
    @State private var exportResult: ExportResult? = nil
    
    // Import state
    @State private var showImportPicker: Bool = false
    @State private var importFormat: ExportFormat = .json
    @State private var isImporting: Bool = false
    @State private var importResult: ImportResult? = nil
    
    // Share sheet
    @State private var exportedFileURL: URL? = nil
    @State private var showShareSheet: Bool = false
    
    enum ExportFormat: String, CaseIterable, Identifiable {
        case json = "JSON"
        case csv = "CSV"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .json:
                return "Best for backup & restore. Preserves all card data including tags, folders, and settings."
            case .csv:
                return "Best for spreadsheet editing. Can be opened in Excel or Google Sheets for bulk editing."
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
    
    enum ExportResult {
        case success(count: Int)
        case error(message: String)
    }
    
    enum ImportResult {
        case success(count: Int)
        case error(message: String)
    }
    
    private var cardsToExport: [Card] {
        if includeArchived {
            return allCards
        } else {
            return filteredCards.filter { !$0.isArchived }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Export Section
                Section {
                    // Format picker with descriptions
                    ForEach(ExportFormat.allCases) { format in
                        Button {
                            exportFormat = format
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: format.icon)
                                    .font(.title2)
                                    .foregroundStyle(exportFormat == format ? Color.accentColor : Color.secondary)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(format.rawValue)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        
                                        if exportFormat == format {
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
                    
                    // Include archived toggle
                    Toggle(isOn: $includeArchived) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Include Archived Cards")
                            Text("\(cardsToExport.count) cards will be exported")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Export button
                    Button {
                        performExport()
                    } label: {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Label("Export \(cardsToExport.count) Cards", systemImage: "square.and.arrow.up")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .disabled(cardsToExport.isEmpty || isExporting)
                    
                    // Export result feedback
                    if let result = exportResult {
                        switch result {
                        case .success(let count):
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Successfully exported \(count) cards")
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
                } header: {
                    Text("Export Cards")
                } footer: {
                    Text("Export your filtered cards to share or backup. JSON preserves all data, CSV is editable in spreadsheets.")
                }
                
                // MARK: - Import Section
                Section {
                    // Format explanation
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "doc.badge.gearshape")
                                .foregroundStyle(.tint)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("JSON Files")
                                    .font(.subheadline.weight(.medium))
                                Text("Import cards exported from TopNote or matching the TopNote format.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "tablecells")
                                .foregroundStyle(.tint)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("CSV Files")
                                    .font(.subheadline.weight(.medium))
                                Text("Import cards from a spreadsheet. First row should be headers.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // Import buttons
                    HStack(spacing: 12) {
                        Button {
                            importFormat = .json
                            showImportPicker = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Import JSON", systemImage: "square.and.arrow.down")
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isImporting)
                        
                        Button {
                            importFormat = .csv
                            showImportPicker = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Import CSV", systemImage: "square.and.arrow.down")
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isImporting)
                    }
                    
                    // Import progress/result
                    if isImporting {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("Importing cards...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
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
                } header: {
                    Text("Import Cards")
                } footer: {
                    Text("Imported cards will be added to your collection. Existing cards won't be duplicated if they have matching creation dates and content.")
                }
                
                // MARK: - Help Section
                Section {
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("**To export:**")
                            Text("1. Choose a format (JSON or CSV)")
                            Text("2. Toggle 'Include Archived' if needed")
                            Text("3. Tap 'Export Cards'")
                            Text("4. Save or share the file")
                            
                            Divider()
                            
                            Text("**To import:**")
                            Text("1. Tap 'Import JSON' or 'Import CSV'")
                            Text("2. Select your file from Files app")
                            Text("3. Cards will be added automatically")
                            
                            Divider()
                            
                            Text("**Tip:** Use JSON for full backups. Use CSV if you want to edit cards in a spreadsheet then re-import.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                        .padding(.vertical, 8)
                    } label: {
                        Label("How to Export & Import", systemImage: "questionmark.circle")
                    }
                }
            }
            .navigationTitle("Manage Cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
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
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    // MARK: - Export Logic
    
    private func performExport() {
        isExporting = true
        exportResult = nil
        
        let cards = cardsToExport
        
        Task {
            do {
                let fileManager = FileManager.default
                guard let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    throw NSError(domain: "ExportError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not access documents directory"])
                }
                
                let fileName: String
                let fileURL: URL
                
                switch exportFormat {
                case .json:
                    let jsonData = try Card.exportCardsToJSON(cards)
                    fileName = "topnote_cards_\(formattedDate()).json"
                    fileURL = dir.appendingPathComponent(fileName)
                    try jsonData.write(to: fileURL)
                    
                case .csv:
                    let csvString = try Card.exportCardsToCSV(cards)
                    fileName = "topnote_cards_\(formattedDate()).csv"
                    fileURL = dir.appendingPathComponent(fileName)
                    try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
                }
                
                await MainActor.run {
                    exportedFileURL = fileURL
                    exportResult = .success(count: cards.count)
                    isExporting = false
                    showShareSheet = true
                }
            } catch {
                await MainActor.run {
                    exportResult = .error(message: error.localizedDescription)
                    isExporting = false
                }
            }
        }
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
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
                
                switch importFormat {
                case .json:
                    let data = try Data(contentsOf: url)
                    if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                        for dict in jsonArray {
                            if let card = CardImport.makeCard(from: dict, context: context) {
                                context.insert(card)
                                importedCount += 1
                            }
                        }
                    }
                    
                case .csv:
                    let csvString = try String(contentsOf: url, encoding: .utf8)
                    let cards = try CardImport.parseCSV(csvString, context: context)
                    for card in cards {
                        context.insert(card)
                        importedCount += 1
                    }
                }
                
                try context.save()
                importResult = .success(count: importedCount)
                
                // Trigger tag deduplication after import (runs on background thread)
                CloudKitSyncHandler.shared.triggerDeduplicationAfterUserAction(container: sharedModelContainer)
                
            } catch {
                importResult = .error(message: "Import failed: \(error.localizedDescription)")
            }
            
        case .failure(let error):
            importResult = .error(message: "Could not open file: \(error.localizedDescription)")
        }
        
        isImporting = false
    }
}

#Preview {
    ExportImportSheet(filteredCards: [], allCards: [])
}

