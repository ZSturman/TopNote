//
//  ConfigurationAppIntent.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import WidgetKit
import AppIntents
import SwiftData

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Top Note Widget" }
    static var description: IntentDescription { "Displays a card from your collection." }

    @Parameter(title: "Card Type", default: [.flashcard, .note, .todo])
    var showCardType: [CardType]

    @Parameter(title: "Folders", default: [], optionsProvider: FolderOptionsProvider())
    var showFolders: [Folder]

    /// When user selects no folders, this returns all folders + the "No Folder" sentinel.
    var effectiveFolders: [Folder] {
        if showFolders.isEmpty {
            do {
                // Prefer the shared container if available (keeps widget/app consistent).
                let container = sharedModelContainer
                let context = ModelContext(container)
                let allFolders = try context.fetch(FetchDescriptor<Folder>())
                return allFolders + [Folder.noFolder]
            } catch {
                // Still include No Folder so nil-folder cards can be shown.
                return [Folder.noFolder]
            }
        } else {
            return showFolders
        }
    }

    /// Convenience for filtering logic
    var includesNoFolder: Bool {
        effectiveFolders.contains(where: { $0.isNoFolderSentinel })
    }
}

// MARK: - Folder Picker Options

/// Provides the options shown in the widget configuration folder picker.
/// Includes a sentinel "No Folder" option so users can explicitly include cards where `folder == nil`.
struct FolderOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [Folder] {
        do {
            // Prefer the shared container if available (keeps widget/app consistent).
            let container = sharedModelContainer
            let context = ModelContext(container)
            let allFolders = try context.fetch(FetchDescriptor<Folder>())
            return allFolders + [Folder.noFolder]
        } catch {
            // Even if fetch fails, still offer the sentinel so selection is possible.
            return [Folder.noFolder]
        }
    }
}
