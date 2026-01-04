//
//  ShareConfigSheet.swift
//  TopNote
//
//  Created by Zachary Sturman on 1/3/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ShareConfigSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    let filteredCards: [Card]
    let allCards: [Card]
    
    // Share options
    @State private var includeArchived: Bool = false
    @State private var includeDeleted: Bool = false
    @State private var includeActivityLogs: Bool = false
    @State private var shareFormat: ShareFormat = .json
    
    // Processing state
    @State private var isProcessing: Bool = false
    @State private var shareResult: ShareResult? = nil
    
    // Share sheet
    @State private var exportedFileURL: URL? = nil
    @State private var showShareSheet: Bool = false
    
    enum ShareFormat: String, CaseIterable, Identifiable {
        case json = "JSON"
        case csv = "CSV"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .json:
                return "Full backup format. Includes all card data and optionally activity logs."
            case .csv:
                return "Spreadsheet format. Good for viewing in Excel or Google Sheets."
            }
        }
        
        var icon: String {
            switch self {
            case .json: return "doc.badge.gearshape"
            case .csv: return "tablecells"
            }
        }
    }
    
    enum ShareResult {
        case success(count: Int)
        case error(message: String)
    }
    
    private var cardsToShare: [Card] {
        var cards = filteredCards.filter { !$0.isArchived && !$0.isDeleted }
        
        if includeArchived {
            cards.append(contentsOf: allCards.filter { $0.isArchived && !$0.isDeleted })
        }
        
        if includeDeleted {
            cards.append(contentsOf: allCards.filter { $0.isDeleted })
        }
        
        return cards
    }
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Format Selection
                Section {
                    ForEach(ShareFormat.allCases) { format in
                        Button {
                            shareFormat = format
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: format.icon)
                                    .font(.title2)
                                    .foregroundStyle(shareFormat == format ? Color.accentColor : Color.secondary)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(format.rawValue)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        
                                        if shareFormat == format {
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
                    Text("Format")
                }
                
                // MARK: - Card Selection
                Section {
                    Toggle(isOn: $includeArchived) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Include Archived Cards")
                            Text("Add archived cards to the export")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Toggle(isOn: $includeDeleted) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Include Deleted Cards")
                            Text("Add cards in the trash to the export")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Cards to share")
                        Spacer()
                        Text("\(cardsToShare.count)")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Card Selection")
                }
                
                // MARK: - Activity Logs
                Section {
                    Toggle(isOn: $includeActivityLogs) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Include Activity Logs")
                            Text("Your card usage history (views, skips, ratings)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Activity Data")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                            Text("Activity logs include your card history such as when cards were viewed, skipped, or rated. This data can be helpful for support requests or analyzing your usage patterns.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if includeActivityLogs {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Activity logs will be included in the export.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // MARK: - Share Action
                Section {
                    Button {
                        performShare()
                    } label: {
                        HStack {
                            Spacer()
                            if isProcessing {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Label("Share \(cardsToShare.count) Cards", systemImage: "square.and.arrow.up")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .disabled(cardsToShare.isEmpty || isProcessing)
                    
                    // Result feedback
                    if let result = shareResult {
                        switch result {
                        case .success(let count):
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Prepared \(count) cards for sharing")
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
                }
            }
            .navigationTitle("Share Cards")
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
    
    // MARK: - Share Logic
    
    private func performShare() {
        isProcessing = true
        shareResult = nil
        
        let cards = cardsToShare
        
        Task {
            do {
                let fileManager = FileManager.default
                guard let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    throw NSError(domain: "ShareError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not access documents directory"])
                }
                
                let fileName: String
                let fileURL: URL
                
                switch shareFormat {
                case .json:
                    let jsonData = try exportCardsWithLogs(cards)
                    fileName = "topnote_share_\(formattedDate()).json"
                    fileURL = dir.appendingPathComponent(fileName)
                    try jsonData.write(to: fileURL)
                    
                case .csv:
                    let csvString = try Card.exportCardsToCSV(cards)
                    fileName = "topnote_share_\(formattedDate()).csv"
                    fileURL = dir.appendingPathComponent(fileName)
                    try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
                }
                
                await MainActor.run {
                    exportedFileURL = fileURL
                    shareResult = .success(count: cards.count)
                    isProcessing = false
                    showShareSheet = true
                }
            } catch {
                await MainActor.run {
                    shareResult = .error(message: error.localizedDescription)
                    isProcessing = false
                }
            }
        }
    }
    
    private func exportCardsWithLogs(_ cards: [Card]) throws -> Data {
        var exportData: [[String: Any]] = []
        
        for card in cards {
            var cardDict = card.toDictionary()
            
            // Add activity logs if enabled
            if includeActivityLogs {
                var activityLog: [String: Any] = [:]
                
                // Enqueue history
                let enqueueFormatter = ISO8601DateFormatter()
                activityLog["enqueues"] = card.enqueues.map { enqueueFormatter.string(from: $0) }
                activityLog["removals"] = card.removals.map { enqueueFormatter.string(from: $0) }
                activityLog["skips"] = card.skips.map { enqueueFormatter.string(from: $0) }
                activityLog["completes"] = card.completes.map { enqueueFormatter.string(from: $0) }
                
                // Metrics
                activityLog["seenCount"] = card.seenCount
                activityLog["skipCount"] = card.skipCount
                
                // Rating history (for flashcards)
                if card.cardType == .flashcard {
                    var ratingHistory: [[String: String]] = []
                    for ratingEntry in card.rating {
                        for (ratingType, date) in ratingEntry {
                            ratingHistory.append([
                                "rating": ratingType.rawValue,
                                "date": enqueueFormatter.string(from: date)
                            ])
                        }
                    }
                    activityLog["ratingHistory"] = ratingHistory
                }
                
                cardDict["activityLog"] = activityLog
            }
            
            exportData.append(cardDict)
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys])
        return jsonData
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Card Extension for Dictionary Export

extension Card {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "cardType": cardType.rawValue,
            "content": content,
            "createdAt": ISO8601DateFormatter().string(from: createdAt),
            "nextTimeInQueue": ISO8601DateFormatter().string(from: nextTimeInQueue),
            "isRecurring": isRecurring,
            "repeatInterval": repeatInterval,
            "initialRepeatInterval": initialRepeatInterval,
            "isArchived": isArchived,
            "isComplete": isComplete,
            "priority": priority.rawValue,
            "skipPolicy": skipPolicy.rawValue,
            "skipEnabled": skipEnabled,
            "resetRepeatIntervalOnComplete": resetRepeatIntervalOnComplete
        ]
        
        if let answer = answer {
            dict["answer"] = answer
        }
        
        if let folder = folder {
            dict["folder"] = folder.name
        }
        
        if let tags = tags, !tags.isEmpty {
            dict["tags"] = tags.map { $0.name }
        }
        
        if let deletedAt = deletedAt {
            dict["deletedAt"] = ISO8601DateFormatter().string(from: deletedAt)
        }
        
        // Flashcard-specific
        if cardType == .flashcard {
            dict["ratingEasyPolicy"] = ratingEasyPolicy.rawValue
            dict["ratingMedPolicy"] = ratingMedPolicy.rawValue
            dict["ratingHardPolicy"] = ratingHardPolicy.rawValue
            dict["answerRevealed"] = answerRevealed
        }
        
        return dict
    }
}

#Preview {
    ShareConfigSheet(filteredCards: [], allCards: [])
}
