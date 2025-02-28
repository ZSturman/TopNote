//
//  RatingTableView.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/25/25.
//

import SwiftUI

struct RatingsTableView: View {
    var card: Card
    
    var body: some View {
        List {
            
            
            Section(header: Text("Ratings").font(.headline)) {
                if card.rating.isEmpty {
                    Text("No Ratings Available")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(card.rating.enumerated()), id: \.offset) { index, ratingEntry in
                        // Each ratingEntry is a dictionary [RatingType: Date]
                        ForEach(Array(ratingEntry.keys), id: \.self) { ratingType in
                            if let date = ratingEntry[ratingType] {
                                HStack {
                                    Text(ratingType.rawValue)
                                    Spacer()
                                    Text(date, formatter: dateFormatter)
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}


struct RatingsTableView_Previews: PreviewProvider {
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
            nextTimeInQueue: Date().addingTimeInterval(3600),
            rating: [
                [.easy: Date().addingTimeInterval(-7200)],
                [.hard: Date().addingTimeInterval(-3600)]
            ]
        )
        
        
        
        RatingsTableView(card: card)
    }
}
