//
//  CardStats.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/25/25.
//

import Foundation
import SwiftUI

struct CardStatsView: View {
    var card: Card

    var body: some View {
        List {
            Section(header: Text("Skips").font(.headline)) {
                Text("Skip Count: \(card.skipCount)")
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()




struct CardStatsView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a dummy card with sample data for preview purposes
        let card = Card(
            createdAt: Date(),
            cardType: .flashCard,
            priorityTypeRaw: .none,
            content: "Sample Card Content",
            skipCount: 3,
            seenCount: 10,
            spacedTimeFrame: 24,
            dynamicTimeframe: true,
            nextTimeInQueue: Date().addingTimeInterval(3600)
            //toDos: []
        )
        
        // Add dummy rating data and quiz results
        card.rating = [
            [.easy: Date().addingTimeInterval(-7200)],
            [.hard: Date().addingTimeInterval(-3600)]
        ]
        
        return CardStatsView(card: card)
    }
}
