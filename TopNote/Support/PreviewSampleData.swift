//
//  PreviewSampleData.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/22/25.
//

import SwiftUI
import SwiftData

@MainActor
let previewContainer: ModelContainer = {
    do {
        let schema = Schema([Card.self, Folder.self, Tag.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        // Create the sample deck data.
        let deck = SampleDeck.create()
        
        // Insert folders (which contain their own cards) into the main context.
        for folder in deck.folders {
            container.mainContext.insert(folder)
        }
        
        // Insert extra cards (which are not assigned to any folder) into the main context.
        for card in deck.extraCards {
            container.mainContext.insert(card)
        }
        
        for tag in deck.tags {
            container.mainContext.insert(tag)
        }
        
        return container
    } catch {
        fatalError("Failed to create container: \(error)")
    }
}()
