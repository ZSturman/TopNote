//
//  CardEntry.swift
//  TopNoteWidgetExtension
//
//  Created by Zachary Sturman on 2/25/25.
//

import Foundation
import WidgetKit

struct CardEntry: TimelineEntry {
    let date: Date            // This represents when the entry was generated ("Last updated")
    let card: Card
    let queueCardCount: Int
    let totalNumberOfCards: Int
    let nextCardForQueue: Card?
    let nextUpdateDate: Date  // New field to show the next update time
}
