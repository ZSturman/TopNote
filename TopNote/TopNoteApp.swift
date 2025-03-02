//
//  TopNoteApp.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/17/25.
//

import SwiftUI
import SwiftData


@main
struct TopNoteApp: App {

    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Card.self, Folder.self, Tag.self])

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        
        WindowGroup {
            ContentView()

        }
        .modelContainer(sharedModelContainer)
 
    }
}
