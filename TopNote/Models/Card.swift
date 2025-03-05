//
//  Card.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/17/25.
//


import Foundation
import SwiftData
import WidgetKit

@Model
final class Card {
    
    // MARK: - Properties
    
    /// Unique identifier for the card.
    var id: UUID = UUID()
    
    /// Timestamp for when the card was created.
    var createdAt: Date = Date()
    
    /// Constructs a deep link URL for the card.
    var url: URL {
        guard let url = URL(string: "topnote://card/\(id)") else {
            fatalError("Failed to construct URL")
        }
        return url
    }
    
    // MARK: - Usage Metrics
    
    var skipCount: Int = 0
    var seenCount: Int = 0
    var timeOnTop: Date?
    var timeInQueue: Date?
    
    // MARK: - Spaced Repetition Settings
    
    /// The time interval (in hours) used for scheduling.
    var spacedTimeFrame: Int = 240
    var dynamicTimeframe: Bool = true
    var nextTimeInQueue: Date = Date()
    var lastRemovedFromQueue: Date?
    
    // MARK: - Flags
    
    var isEssential: Bool = false
    var archived: Bool = false
    var hasBeenFlipped: Bool = false
    
    // MARK: - Rating Storage
    
    @Attribute var ratingData: Data?
    var rating: [[RatingType: Date]] {
        get {
            guard let data = ratingData,
                  let decoded = try? JSONDecoder().decode([[String: Date]].self, from: data)
            else { return [] }
            return decoded.compactMap { dict in
                var newDict: [RatingType: Date] = [:]
                for (key, value) in dict {
                    if let ratingType = RatingType(rawValue: key) {
                        newDict[ratingType] = value
                    }
                }
                return newDict
            }
        }
        set {
            let dicts = newValue.map { dict -> [String: Date] in
                var newDict: [String: Date] = [:]
                for (key, value) in dict {
                    newDict[key.rawValue] = value
                }
                return newDict
            }
            ratingData = try? JSONEncoder().encode(dicts)
        }
    }
    
    // MARK: - Relationships
    
    /// Many-to-many relationship with tags.
    @Relationship var tags: [Tag]?
    
    /// Unwraps the tags, providing an empty array if nil.
    var unwrappedTags: [Tag] {
        tags ?? []
    }
    
    /// Optional relationship to a folder.
    @Relationship(deleteRule: .nullify)
    var folder: Folder?
    
    // MARK: - Card Content and Classification
    
    var cardTypeRaw: String = CardType.none.rawValue
    var priorityRaw: String = PriorityType.none.rawValue
    var content: String = ""
    var back: String?
    
    /// Computed property to get or set the card type.
    var cardType: CardType {
        get { CardType(rawValue: cardTypeRaw) ?? .flashCard }
        set { cardTypeRaw = newValue.rawValue }
    }
    
    /// Computed property to get or set the card's priority.
    var priority: PriorityType {
        get { PriorityType(rawValue: priorityRaw) ?? .low }
        set { priorityRaw = newValue.rawValue }
    }
    
    // MARK: - Initializer
    
    init(
        createdAt: Date,
        cardType: CardType,
        priorityTypeRaw: PriorityType,
        content: String = "",
        isEssential: Bool = false,
        skipCount: Int = 0,
        seenCount: Int = 0,
        timeOnTop: Date? = nil,
        timeInQueue: Date? = nil,
        spacedTimeFrame: Int = 240,
        dynamicTimeframe: Bool = true,
        nextTimeInQueue: Date = Date(),
        lastRemovedFromQueue: Date? = nil,
        folder: Folder? = nil,
        tags: [Tag] = [],
        back: String? = nil,
        rating: [[RatingType: Date]] = [],
        archived: Bool = false,
        hasBeenFlipped: Bool = false
    ) {
        self.id = UUID()
        self.createdAt = createdAt
        self.cardTypeRaw = cardType.rawValue
        self.priorityRaw = priorityTypeRaw.rawValue
        self.content = content
        self.back = back
        self.isEssential = isEssential
        self.skipCount = skipCount
        self.seenCount = seenCount
        self.timeOnTop = timeOnTop
        self.timeInQueue = timeInQueue
        self.spacedTimeFrame = spacedTimeFrame
        self.dynamicTimeframe = dynamicTimeframe
        self.nextTimeInQueue = nextTimeInQueue
        self.lastRemovedFromQueue = lastRemovedFromQueue
        self.folder = folder
        self.tags = tags
        self.rating = rating
        self.archived = archived
        self.hasBeenFlipped = hasBeenFlipped
    }
    
    // MARK: - Public Methods
    
    /// Determines if the card is due to be enqueued.
    func isEnqueue(currentDate: Date) -> Bool {
        return currentDate >= nextTimeInQueue
    }
    
    /// Returns the time interval until the card is next queued.
    func timeUntilNextInQueue(currentDate: Date) -> TimeInterval {
        return self.nextTimeInQueue.timeIntervalSince(currentDate)
    }
    
    /// Returns the number of hours until the card is queued.
    func hoursUntilQueued(currentDate: Date) -> Int {
        return Calendar.current.dateComponents([.hour], from: currentDate, to: nextTimeInQueue).hour ?? 0
    }
}
