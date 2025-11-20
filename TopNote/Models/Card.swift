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
final class CardTag {
    var id: UUID = UUID()
    var name: String = ""
    @Relationship(deleteRule: .nullify, inverse: \Card.tags)
    var cards: [Card]?
    
    var unwrappedCards: [Card] {
        cards ?? []
    }
    
    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}


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
    
    // MARK: - Spaced Repetition Settings
    
    /// The time interval (in hours) used for scheduling.
    var repeatInterval: Int = 240
    var initialRepeatInterval: Int = 240
    
//    var isDynamic: Bool = true
    var nextTimeInQueue: Date = Date()
    
    var skipPolicy     : RepeatPolicy         = RepeatPolicy.none
    var ratingEasyPolicy: RepeatPolicy = RepeatPolicy.mild
    var ratingMedPolicy: RepeatPolicy = RepeatPolicy.none
    var ratingHardPolicy: RepeatPolicy = RepeatPolicy.aggressive
    
    // MARK: - Flags
    var isRecurring: Bool = false
    var isArchived: Bool = false
    var answerRevealed: Bool = false
    var isComplete: Bool = false
    var resetRepeatIntervalOnComplete: Bool = true
    var skipEnabled: Bool = true
        
    
    // MARK: - Rating Storage
    @Attribute var ratingData: Data?
    /// Stores the dates when the card was marked complete.
    @Attribute var completeData: Data?
    /// Stores the dates when the card was enqueued.
    @Attribute var enqueueData: Data?
    /// Stores the dates when the card was removed from the queue.
    @Attribute var removalData: Data?
    /// Stores the dates when the card was skipped.
    @Attribute var skipData: Data?
    
    /// Stores an array of rating dictionaries with keys as RatingType and values as Date.
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
    
    /// Stores an array of Dates representing when the card was marked complete.
    var completes: [Date] {
        get {
            guard let data = completeData,
                  let decoded = try? JSONDecoder().decode([Date].self, from: data)
            else { return [] }
            return decoded
        }
        set {
            completeData = try? JSONEncoder().encode(newValue)
        }
    }
    
    /// Stores an array of Dates representing when the card was enqueued.
    var enqueues: [Date] {
        get {
            guard let data = enqueueData,
                  let decoded = try? JSONDecoder().decode([Date].self, from: data)
            else { return [] }
            return decoded
        }
        set {
            enqueueData = try? JSONEncoder().encode(newValue)
        }
    }
    
    /// Stores an array of Dates representing when the card was removed from the queue.
    var removals: [Date] {
        get {
            guard let data = removalData,
                  let decoded = try? JSONDecoder().decode([Date].self, from: data)
            else { return [] }
            return decoded
        }
        set {
            removalData = try? JSONEncoder().encode(newValue)
        }
    }
    
    /// Stores an array of Dates representing when the card was skipped.
    var skips: [Date] {
        get {
            guard let data = skipData,
                  let decoded = try? JSONDecoder().decode([Date].self, from: data)
            else { return [] }
            return decoded
        }
        set {
            skipData = try? JSONEncoder().encode(newValue)
        }
    }
    
    // MARK: - Relationships
    /// Many-to-many relationship with tags.
    @Relationship var tags: [CardTag]?
    
    /// Unwraps the tags, providing an empty array if nil.
    var unwrappedTags: [CardTag] {
        tags ?? []
    }
    
    /// Optional relationship to a folder.
    @Relationship(deleteRule: .nullify)
    var folder: Folder?
    
    // MARK: - Card Content and Classification
    
    var cardTypeRaw: String = CardType.todo.rawValue
    var priorityRaw: String = PriorityType.none.rawValue
    var content: String = ""
    var answer: String?
    
    /// Computed property to get or set the card type.
    var cardType: CardType {
        get { CardType(rawValue: cardTypeRaw) ?? .todo }
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
        isRecurring: Bool = false,
        skipCount: Int = 0,
        seenCount: Int = 0,
        repeatInterval: Int = 240,
        initialRepeatInterval: Int = 240,
        nextTimeInQueue: Date = Date().addingTimeInterval(3600), // 1 hour from now
        folder: Folder? = nil,
        tags: [CardTag] = [],
        answer: String? = nil,
        rating: [[RatingType: Date]] = [],
        isArchived: Bool = false,
        answerRevealed: Bool = false,
        skipPolicy: RepeatPolicy = RepeatPolicy.none,
        ratingEasyPolicy: RepeatPolicy = RepeatPolicy.mild,
        ratingMedPolicy: RepeatPolicy = RepeatPolicy.none,
        ratingHardPolicy: RepeatPolicy = RepeatPolicy.aggressive,
        isComplete: Bool = false,
        resetRepeatIntervalOnComplete: Bool = true,
        skipEnabled: Bool = true
    ) {
        self.id = UUID()
        self.createdAt = createdAt
        self.cardTypeRaw = cardType.rawValue
        self.priorityRaw = priorityTypeRaw.rawValue
        self.content = content
        self.answer = answer
        self.isRecurring = isRecurring
        self.skipCount = skipCount
        self.seenCount = seenCount
        self.repeatInterval = repeatInterval
        self.initialRepeatInterval = initialRepeatInterval
        self.nextTimeInQueue = nextTimeInQueue
        self.folder = folder
        self.tags = tags
        self.rating = rating
        self.isArchived = isArchived
        self.answerRevealed = answerRevealed
        self.skipPolicy = skipPolicy
        self.ratingEasyPolicy = ratingEasyPolicy
        self.ratingMedPolicy = ratingMedPolicy
        self.ratingHardPolicy = ratingHardPolicy
        self.isComplete = isComplete
        self.resetRepeatIntervalOnComplete = resetRepeatIntervalOnComplete
        self.skipEnabled = skipEnabled
    }
    
    
    
    
    func submitFlashcardRating(_ rating: RatingType, at date: Date) {
        // append to ratings,
        // if enqueue && isRecurring -> update the next in queue
        // if enqueue && !isRecurring -> archive
        self.rating.append([rating: date])
        self.answerRevealed = false
        if isEnqueue(currentDate: date) {
            if isRecurring {
                switch rating {
                case .easy:
                    scheduleNext(
                 
                        baseInterval: repeatInterval,
                        from: date,
                        as: .easy
                    )
                case .good:
                    scheduleNext(
                  
                        baseInterval: repeatInterval,
                        from: date,
                        as: .good
          
                    )
                case .hard:
                    scheduleNext(
                   
                        baseInterval: repeatInterval,
                        from: date,
                        as: .hard
                    
                    )
                }
            } else {
                scheduleNext(
             
                    baseInterval: repeatInterval,
                    from: date,
                    as: .easy
                )
                archive(at: date)
            }
            
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func markAsComplete(at currentDate: Date) {
        self.answerRevealed = false
        
        self.completes.append(currentDate)
        if resetRepeatIntervalOnComplete {
            self.repeatInterval = initialRepeatInterval
        }

            if isRecurring {
                scheduleNext(
                    baseInterval: resetRepeatIntervalOnComplete ? initialRepeatInterval : repeatInterval,
                    from: currentDate,
                    as: .complete
                )
            } else {
                scheduleNext(
                    baseInterval: resetRepeatIntervalOnComplete ? initialRepeatInterval : repeatInterval,
                    from: currentDate,
                    as: .complete
                )
                archive(at: currentDate)
                self.isComplete = true
            }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func markAsNotComplete(at currentDate: Date) {
        
        if completes.last != nil {
            completes.removeLast()
        }
       isComplete = false
        self.answerRevealed = false
        if isArchived, isRecurring {
            scheduleNext(
       
                baseInterval: repeatInterval,
                from: currentDate,
                as: .notComplete
            )
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func showAnswer(at currentDate: Date) {
        self.answerRevealed = true
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func skip(at currentDate: Date) {
        self.answerRevealed = false
        self.skipCount += 1
        self.skips.append(currentDate)
                scheduleNext(
                    baseInterval: repeatInterval,
                    from: currentDate,
                    as: .skip
                )
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func next(at currentDate: Date) {
        
        // If !isEnqueue exit the function
        guard isEnqueue(currentDate: currentDate) else {
            return
        }
        self.answerRevealed = false
        self.removals.append(currentDate)

            if isRecurring {
                scheduleNext(
                    baseInterval: repeatInterval,
                    from: currentDate,
                    as: .next
                )
            } else {
                scheduleNext(
                    baseInterval: repeatInterval,
                    from: currentDate,
                    as: .next
                )
                archive(at: currentDate)
            }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func archive(at currentDate: Date) {
        // If already archived, exit the function
        guard !isArchived else {
            return
        }
        self.answerRevealed = false
        // If isEqneue append to removals and set isArchived to true
        if isEnqueue(currentDate: currentDate) {
            self.removals.append(currentDate)
        }
        self.isArchived = true
        self.nextTimeInQueue = .distantFuture
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func unarchive(at currentDate: Date) {
        // If not archived, exit the function
        guard isArchived else {
            return
        }
        self.answerRevealed = false
        self.isArchived = false
        self.isComplete = false
        scheduleNext(
            baseInterval: repeatInterval,
            from: currentDate,
            as: .unarchive
        )
        WidgetCenter.shared.reloadAllTimelines()
    }
    

        
    /// Add card to the queue.
    /// - Parameter currentDate: The current date to set as the next time in queue.
    func enqueue(at currentDate: Date) {
        // If already enqueued, exit the function
        guard !isEnqueue(currentDate: currentDate) else {
            return
        }
        self.isArchived = false
        self.isComplete = false
        self.answerRevealed = false
        self.seenCount += 1
        self.nextTimeInQueue = currentDate
        self.enqueues.append(currentDate)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // add tag to the card
    /// Adds a tag to the card.
    /// - Parameter tag: The tag to be added.
    func addTag(_ tag: CardTag) {
        if !(unwrappedTags.contains { $0.id == tag.id }) {
            self.tags?.append(tag)
        }
    }
    
    /// Removes a tag from the card.
    /// - Parameter tag: The tag to be removed.
    func removeTag(_ tag: CardTag) {
        if let index = unwrappedTags.firstIndex(where: { $0.id == tag.id }) {
            self.tags?.remove(at: index)
        }
    }
    
    
    
    enum DequeueOption: String {
        case skip, next, complete, notComplete,  easy, good, hard, unarchive
    }
    
    
    /// Applies policy.multiplier to the baseInterval (in hours),
    /// updates `repeatInterval`, and sets `nextTimeInQueue`.
    private func scheduleNext(
        //sing policy: RepeatPolicy,
        baseInterval: Int,
        from date: Date,
        as dequeued: DequeueOption
    ) {

        let nextInterval: Int
        
        switch (dequeued) {
        case .skip:
            if cardType == .note {
                // Notes should always have MORE time added when skipped
                // Use the reciprocal to ensure we always increase the interval
                let multiplier = skipPolicy.skipMultiplier > 0 ? (1.0 / skipPolicy.skipMultiplier) : 2.0
                nextInterval = Int(Double(baseInterval) * max(multiplier, 2.0)) // Minimum 2x interval
            } else {
                nextInterval = Int(Double(baseInterval) * skipPolicy.skipMultiplier)
            }
            
            
        case .easy:
            // multiply the repeatInterval by the ratingEasyPolicy multiplier
            nextInterval = Int(Double(baseInterval) * ratingEasyPolicy.easyMultiplier)
        case .good:
            // multiply the repeatInterval by the ratingMedPolicy multiplier
            nextInterval = Int(Double(baseInterval) * ratingMedPolicy.goodMultiplier)
        case .hard:
            // multiply the repeatInterval by the ratingHardPolicy multiplier
            nextInterval = Int(Double(baseInterval) * ratingHardPolicy.hardMultiplier)
        case .next, .complete, .unarchive, .notComplete:
            // Use the baseInterval directly for next and complete actions
            nextInterval = baseInterval
        }
        // Clamp the next interval between 1 hour and 1 year
        let clampedInterval = max(24, min(nextInterval, 8760)) // Minimum 24 hours (1 day), maximum 8760 hours (1 year)
        self.repeatInterval = clampedInterval
        // Update the nextTimeInQueue based on the new repeatInterval
        self.nextTimeInQueue = date.addingTimeInterval(TimeInterval(clampedInterval * 3600)) // Convert hours to seconds
     
    }
    

    
    // MARK: - Public Methods
    /// Determines if the card is due to be enqueued.
    /// - Parameter currentDate: The current date to check against.
    /// - Returns: A Boolean indicating whether the card is enqueued.
    func isEnqueue(currentDate: Date) -> Bool {
        return !isArchived && currentDate >= nextTimeInQueue
    }
    
    /// Returns the time interval until the card is next queued.
    /// - Parameter currentDate: The current date to check against.
    /// - Returns: The time interval in seconds until the card is next queued.
    func timeUntilNextInQueue(currentDate: Date) -> TimeInterval {
        return self.nextTimeInQueue.timeIntervalSince(currentDate)
    }
    
    /// Returns the number of hours until the card is queued.
    /// - Parameter currentDate: The current date to check against.
    /// - Returns: The number of hours until the card is queued.
    func hoursUntilQueued(currentDate: Date) -> Int {
        return Calendar.current.dateComponents([.hour], from: currentDate, to: nextTimeInQueue).hour ?? 0
    }
    
    
    // MARK: - Rating Aggregation
    /// Aggregates the rating events from the rating history.
    var ratingEvents: [RatingEvent] {
        rating.compactMap { dict in
            if let (rating, date) = dict.first {
                return RatingEvent(rating: rating, date: date)
            }
            return nil
        }
    }
    
    /// Computes counts for each rating type.
    var ratingCounts: [RatingCount] {
        let grouped = Dictionary(grouping: ratingEvents, by: { $0.rating })
        return grouped.map { RatingCount(rating: $0.key, count: $0.value.count) }
            .sorted { $0.rating.rawValue < $1.rating.rawValue }
    }
    
    var displayContent: String {
        content.isEmpty ? "Default content here" : content
    }

    var displayAnswer: String {
        if let answer, !answer.isEmpty {
            return answer
        }
        return "Answer here..."
    }
    
    
    var displayedDateForQueue: String {
        if isArchived {
            return "Removed from queue"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        if isEnqueue(currentDate: Date()) {
            let nextTimeInQueue = self.nextTimeInQueue.timeIntervalSinceNow
            let hours = Int(nextTimeInQueue / 3600)
            if nextTimeInQueue < 0 && abs(hours) < 24 {
                return "Queued \(abs(hours)) hours ago"
            } else if nextTimeInQueue < 0 && abs(hours) >= 24 && abs(hours) < 168 {
                let days = abs(hours) / 24
                return "Queued \(days) days ago"
            } else  {
                let weeks = abs(hours) / 168
                return "Queued \(weeks) weeks ago"
            }
        } else {
            // Show interval until next in queue
            let now = Date()
            let interval = self.nextTimeInQueue.timeIntervalSince(now)
            if interval < 3600 {
                let minutes = max(1, Int(interval / 60))
                return "Next: in \(minutes) min"
            } else if interval < 86400 {
                let hours = Int(interval / 3600)
                return "Next: in \(hours) hours"
            } else if interval < 604800 {
                let days = Int(interval / 86400)
                return "Next: in \(days) days"
            } else {
                let weeks = Int(interval / 604800)
                return "Next: in \(weeks) weeks"
            }
        }
    }
    
    /// Returns the base recurring schedule derived from initialRepeatInterval
    var displayedBaseSchedule: String {
        guard isRecurring else { return "Not recurring" }
        
        let hours = initialRepeatInterval
        switch hours {
        case 24: return "Daily"
        case 48: return "Every 2 Days"
        case 72: return "Every 3 Days"
        case 168: return "Weekly"
        case 240: return "Every 10 Days"
        case 336: return "Biweekly"
        case 720: return "Monthly"
        default:
            // For custom intervals
            if hours < 48 {
                return "\(hours) hours"
            } else if hours < 168 {
                let days = hours / 24
                return "Every \(days) days"
            } else if hours < 720 {
                let weeks = hours / 168
                return "Every \(weeks) weeks"
            } else {
                let months = hours / 720
                return "Every \(months) months"
            }
        }
    }
    
    /// Returns the current calculated interval (may differ due to spaced repetition)
    var displayedCurrentInterval: String {
        let hours = repeatInterval
        
        if hours < 48 {
            return "\(hours) hours"
        } else if hours < 168 {
            let days = hours / 24
            return "\(days) day\(days == 1 ? "" : "s")"
        } else if hours < 720 {
            let weeks = hours / 168
            return "\(weeks) week\(weeks == 1 ? "" : "s")"
        } else {
            let months = hours / 720
            return "\(months) month\(months == 1 ? "" : "s")"
        }
    }
    
    /// Shows schedule info for card row - includes both base and current if they differ
    var displayedScheduleForRow: String {
        guard isRecurring else { return "" }
        
        // If intervals match, just show base schedule
        if repeatInterval == initialRepeatInterval {
            return "Repeats: \(displayedBaseSchedule)"
        } else {
            // Show that it's been adjusted
            return "Repeats: \(displayedBaseSchedule) → \(displayedCurrentInterval)"
        }
    }
    
    /// Shows detailed schedule info for details view
    var displayedScheduleDetails: (base: String, current: String, isAdjusted: Bool) {
        let base = displayedBaseSchedule
        let current = displayedCurrentInterval
        let isAdjusted = repeatInterval != initialRepeatInterval
        
        return (base, current, isAdjusted)
    }

    
    var displayedRecurringMessageShort: String {
        if !isRecurring, !isArchived {
            switch cardType {
            case .todo:
                return skipEnabled ? "Completing this todo will archive it." : "Completing this todo will archive it."
            case .flashcard:
                return skipEnabled ? "Rating will archive this flashcard." : "Rating will archive this flashcard."
            case .note:
                return skipEnabled ? "Selecting 'Next' will archive this note." : "Selecting 'Next' will archive this note."
            }
        }
        return ""
    }

    var displayedRecurringMessageLong: String {
        if !isRecurring, !isArchived {
            switch cardType {
            case .todo:
                if skipEnabled {
                    return "When completed, this todo will not repeat and will be archived. Skip to remove from queue and see again later or update the card to make it recurring."
                } else {
                    return "When completed, this todo will not repeat and will be archived. To see again later, update the card to make it recurring."
                }
            case .flashcard:
                if skipEnabled {
                    return "When answer rating submitted, this flashcard will not repeat and will be archived. Skip to remove from queue and see again later or update the card to make it recurring."
                } else {
                    return "When answer rating submitted, this flashcard will not repeat and will be archived. To see again later, update the card to make it recurring."
                }
            case .note:
                if skipEnabled {
                    return "When 'Next' selected, this note will not repeat and will be archived. Skip to remove from queue and see again later or update the card to make it recurring."
                } else {
                    return "When 'Next' selected,, this note will not repeat and will be archived. To see again later, update the card to make it recurring."
                }
            }
        }
        return ""
    }

    var displayedRecurringMessage: String { displayedRecurringMessageLong }
        
}

// MARK: - Export Structures
struct CardExport: Codable {
    let createdAt: Date
    let cardType: String // replaces cardTypeRaw
    let content: String
    let answer: String?
    let isRecurring: Bool
    let skipCount: Int
    let seenCount: Int
    let repeatInterval: Int
    let initialRepeatInterval: Int
    let isArchived: Bool
    let isComplete: Bool
    let resetRepeatIntervalOnComplete: Bool
    let skipEnabled: Bool
    let skipPolicy: RepeatPolicy
    let ratingEasyPolicy: RepeatPolicy
    let ratingMedPolicy: RepeatPolicy
    let ratingHardPolicy: RepeatPolicy
    let tags: [String] // tag names
    let folder: String // folder name or empty string
    /// The card's priority as a string (e.g., 'High', 'Medium', etc.)
    let priority: String
    /// Array of dates when the card was enqueued
    let enqueues: [Date]
    /// Array of dates when the card was skipped
    let skips: [Date]
    /// Array of dates when the card was removed from the queue
    let removals: [Date]
    /// Array of dates when the card was completed
    let completes: [Date]
    /// Array of rating events with rating type and date
    let ratings: [[String: Date]]
}

// MARK: - Card Export Extension
extension Card {
    var exportDTO: CardExport {
        // Convert rating array to exportable format
        let ratingsForExport = rating.map { dict -> [String: Date] in
            var newDict: [String: Date] = [:]
            for (key, value) in dict {
                newDict[key.rawValue] = value
            }
            return newDict
        }
        
        return CardExport(
            createdAt: createdAt,
            cardType: cardTypeRaw,
            content: content,
            answer: answer,
            isRecurring: isRecurring,
            skipCount: skipCount,
            seenCount: seenCount,
            repeatInterval: repeatInterval,
            initialRepeatInterval: initialRepeatInterval,
            isArchived: isArchived,
            isComplete: isComplete,
            resetRepeatIntervalOnComplete: resetRepeatIntervalOnComplete,
            skipEnabled: skipEnabled,
            skipPolicy: skipPolicy,
            ratingEasyPolicy: ratingEasyPolicy,
            ratingMedPolicy: ratingMedPolicy,
            ratingHardPolicy: ratingHardPolicy,
            tags: unwrappedTags.map { $0.name },
            folder: folder?.name ?? "",
            priority: priorityRaw,
            enqueues: enqueues,
            skips: skips,
            removals: removals,
            completes: completes,
            ratings: ratingsForExport
        )
    }

    static func exportCardsToJSON(_ cards: [Card]) throws -> Data {
        let exports = cards.map { $0.exportDTO }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(exports)
    }
    
    static func exportCardsToCSV(_ cards: [Card]) throws -> String {
        let isoFormatter = ISO8601DateFormatter()
        
        // CSV Header
        var csv = "cardType,content,answer,createdAt,nextTimeInQueue,isRecurring,skipCount,seenCount,repeatInterval,initialRepeatInterval,folder,tags,isArchived,skipPolicy,ratingEasyPolicy,ratingMedPolicy,ratingHardPolicy,isComplete,answerRevealed,resetRepeatIntervalOnComplete,skipEnabled\n"
        
        for card in cards {
            let cardType = card.cardType.rawValue
            let content = escapeCSV(card.content)
            let answer = escapeCSV(card.answer ?? "")
            let createdAt = isoFormatter.string(from: card.createdAt)
            let nextTimeInQueue = isoFormatter.string(from: card.nextTimeInQueue)
            let isRecurring = card.isRecurring ? "true" : "false"
            let skipCount = "\(card.skipCount)"
            let seenCount = "\(card.seenCount)"
            let repeatInterval = "\(card.repeatInterval)"
            let initialRepeatInterval = "\(card.initialRepeatInterval)"
            let folder = escapeCSV(card.folder?.name ?? "")
            let tags = escapeCSV(card.unwrappedTags.map { $0.name }.joined(separator: ";"))
            let isArchived = card.isArchived ? "true" : "false"
            let skipPolicy = card.skipPolicy.rawValue
            let ratingEasyPolicy = card.ratingEasyPolicy.rawValue
            let ratingMedPolicy = card.ratingMedPolicy.rawValue
            let ratingHardPolicy = card.ratingHardPolicy.rawValue
            let isComplete = card.isComplete ? "true" : "false"
            let answerRevealed = card.answerRevealed ? "true" : "false"
            let resetRepeatIntervalOnComplete = card.resetRepeatIntervalOnComplete ? "true" : "false"
            let skipEnabled = card.skipEnabled ? "true" : "false"
            
            csv += "\(cardType),\(content),\(answer),\(createdAt),\(nextTimeInQueue),\(isRecurring),\(skipCount),\(seenCount),\(repeatInterval),\(initialRepeatInterval),\(folder),\(tags),\(isArchived),\(skipPolicy),\(ratingEasyPolicy),\(ratingMedPolicy),\(ratingHardPolicy),\(isComplete),\(answerRevealed),\(resetRepeatIntervalOnComplete),\(skipEnabled)\n"
        }
        
        return csv
    }
    
    private static func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return string
    }
}

