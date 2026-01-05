//
//  ExportSheet.swift
//  TopNote
//
//  Created by Zachary Sturman on 1/3/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExportSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    let filteredCards: [Card]
    let allCards: [Card]
    
    // Export state
    @State private var exportFormat: ExportFormat = .json
    @State private var includeArchived: Bool = false
    @State private var isExporting: Bool = false
    @State private var exportResult: ExportResult? = nil
    
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
                    Text("Export your cards to share or backup. JSON preserves all data, CSV is editable in spreadsheets.")
                }
            }
            .navigationTitle("Export Cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
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
}

#Preview {
    ExportSheet(filteredCards: [], allCards: [])
}
