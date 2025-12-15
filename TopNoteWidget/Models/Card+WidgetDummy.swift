//
//  Card+WidgetDummy.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import Foundation

extension Card {
    static func makeDummy() -> Card {
        Card(
            createdAt: Date(),
            cardType: .note,
            priorityTypeRaw: .none,
            content: "",
            isRecurring: false,
            skipCount: 0,
            seenCount: 0,
            repeatInterval: 0,
            nextTimeInQueue: Date(),
            folder: nil,
            tags: [],
            answer: nil,
            rating: [],
            isArchived: false,
            skipPolicy: .none,
            ratingEasyPolicy: .none,
            ratingMedPolicy: .none,
            ratingHardPolicy: .none
        )
    }

    var isDummy: Bool {
        content.isEmpty &&
        !isRecurring &&
        skipCount == 0 &&
        seenCount == 0 &&
        tags?.isEmpty != false
    }
}
