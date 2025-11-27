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
            return try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false
                )
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

