//
//  SharedIntentHelpers.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import Foundation
import SwiftData

@MainActor
func withSharedContext<T>(_ work: @MainActor (ModelContext) throws -> T) rethrows -> T {
    let container = sharedModelContainer
    let context = ModelContext(container)
    return try work(context)
}

func fetchCardModel(_ context: ModelContext, id: UUID) throws -> Card? {
    let fetchDescriptor = FetchDescriptor<Card>(predicate: #Predicate { card in
        card.id == id
    })
    return try context.fetch(fetchDescriptor).first
}
