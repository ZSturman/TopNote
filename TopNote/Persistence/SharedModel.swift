//
//  SharedModel.swift
//  TopNote
//
//  Created by Zachary Sturman on 8/4/25.
//

import Foundation
import SwiftData

public let sharedModelContainer: ModelContainer = {
        do {
            let schema = Schema([Card.self, Folder.self])
            
            // Use App Group container for shared access between app and widget
            let appGroupID = "group.com.zacharysturman.topnote"
            
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .identifier("group.com.zacharysturman.topnote")
            )
            
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

