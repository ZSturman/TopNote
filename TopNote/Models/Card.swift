//
//  Card.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/17/25.
//

import Foundation
import SwiftData
import WidgetKit

// MARK: - Enums

enum CardType: String, CaseIterable, Identifiable {
    case flashCard = "Flash Card"
    case none = "Plain"
    
    var id: String { self.rawValue }

}


enum PriorityType: String, CaseIterable, Identifiable {
    case none = "None"
    case low = "Low"
    case med = "Medium"
    case high = "High"
    
    var id: String { self.rawValue }
}

enum RatingType: String, CaseIterable, Identifiable, Codable {
    case easy = "Easy"
    case good = "Good"
    case hard = "Hard"
    
    var id: String { self.rawValue }
    
    var systemImage: String {
        switch self {
        case .easy:
            return "trophy"
        case .good:
            return "hand.thumbsup.fill"
        case .hard:
            return "exclamationmark.questionmark"
        }
    }
}




// MARK: - Card Model

@Model
final class Card {
    // MARK: Properties
    
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var url: URL {
        guard let url = URL(string: "topnote://card/\(id)") else {
            fatalError("Failed to construct URL")
        }
        return url
    }
    
    var skipCount: Int = 0
    var seenCount: Int = 0
    var timeOnTop: Date?
    var timeInQueue: Date?
    var spacedTimeFrame: Int = 240 // In Hours
    var isEssential: Bool = false
    var dynamicTimeframe: Bool = true
    var nextTimeInQueue: Date = Date()
    var lastRemovedFromQueue: Date?
    
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
            // Removed dynamic adjustment here.
        }
    }
    
    //var isCorrect: [[Bool: Date]] = []  // Removed didSet observer.
    
    @Relationship var tags: [Tag]?
//    @Attribute var toDos: [ToDo] = [] {
//        didSet {
//            updateAllComplete()
//        }
//    }
    
    var unwrappedTags: [Tag] {
        tags ?? []
    }
    
    @Relationship(deleteRule: .nullify)
    var folder: Folder? // Optional to allow cards to exist without a folder
    
    var cardTypeRaw: String = CardType.none.rawValue
    var priorityRaw: String = PriorityType.none.rawValue
    
    // Specific to card type.
    var back: String?
    var content: String = ""
    //var potentialAnswersData: Data?
    
    var archived: Bool = false
    

    
    var cardType: CardType {
        get { CardType(rawValue: cardTypeRaw) ?? .flashCard }
        set { cardTypeRaw = newValue.rawValue }
    }
    
    var priority: PriorityType {
        get { PriorityType(rawValue: priorityRaw) ?? .low }
        set { priorityRaw = newValue.rawValue }
    }
    
    var hasBeenFlipped: Bool = false
    
    
    
    // MARK: Initializer
    
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
        addedOnTop: Date? = nil,
        addedToQueue: Date? = nil,
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
        self.cardTypeRaw = cardType.rawValue
        self.isEssential = isEssential
        self.createdAt = createdAt
        self.skipCount = skipCount
        self.seenCount = seenCount
        self.timeOnTop = timeOnTop
        self.timeInQueue = timeInQueue
        self.spacedTimeFrame = spacedTimeFrame
        self.dynamicTimeframe = dynamicTimeframe
        self.nextTimeInQueue = nextTimeInQueue
        self.lastRemovedFromQueue = lastRemovedFromQueue
        self.folder = folder
        self.priorityRaw = priorityTypeRaw.rawValue
        self.back = back
        self.content = content
        self.rating = rating
        self.archived = archived
        self.hasBeenFlipped = hasBeenFlipped
        
    }
    
    // MARK: Public Methods
    
    func isEnqueue(currentDate: Date) -> Bool {
        return currentDate >= nextTimeInQueue
    }
    
    func timeUntilNextInQueue(currentDate: Date) -> TimeInterval {
        return self.nextTimeInQueue.timeIntervalSince(currentDate)
    }
    
    func hoursUntilQueued(currentDate: Date) -> Int {
        return Calendar.current.dateComponents([.hour], from: currentDate, to: nextTimeInQueue).hour ?? 0
    }
}

extension PriorityType {
    var sortValue: Int {
        switch self {
        case .high: return 1
        case .med: return 2
        case .low: return 3
        case .none: return 4
        }
    }
}



struct StatData: Identifiable {
    var id = UUID()
    var category: String
    var count: Int
}


struct RatingEvent: Identifiable {
    let id = UUID()
    let rating: RatingType
    let date: Date
}

struct RatingCount: Identifiable {
    var id: String { rating.rawValue }
    let rating: RatingType
    let count: Int
}

extension Card {
    
    func updateCardContent(content: String) async throws {
        self.content = content
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func updateCardBackContent(backContent: String) async throws {
        self.back = backContent
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func updatePriorityValue(priority: PriorityType) async throws {
        self.priority = priority
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func addCardToQueue(currentDate: Date) async throws {
        self.nextTimeInQueue = currentDate
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func updateSpacedTimeframe(multiplier: Double) async throws  {
        let newTimeframe: Int = Int(Double(self.spacedTimeFrame) * multiplier)
        
        if newTimeframe < 1 {
            self.spacedTimeFrame = 1
        } else if newTimeframe > 8760 {
            self.spacedTimeFrame = 8760
        } else {
            self.spacedTimeFrame = newTimeframe
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    

    
    func submitFlashcardRating(currentDate: Date, rating: RatingType) async throws {
        if self.dynamicTimeframe {
            switch rating {
            case .easy:
                try await updateSpacedTimeframe(multiplier: 1.5)
            case .good:
                try await updateSpacedTimeframe(multiplier: 1)
            case .hard:
                try await updateSpacedTimeframe(multiplier: 0.5)
            }
        }
        
        self.rating.append([rating: currentDate])
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func updateNextInQueueDate(at currentDate: Date) async throws {
        if let newNextDate = Calendar.current.date(byAdding: .hour, value: self.spacedTimeFrame, to: currentDate) {
            self.nextTimeInQueue = newNextDate
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // TODO: Set a min/ max for valeu
    func manuallyUpdateSpacedTimeFrame(newValue: Int) async throws {
        self.spacedTimeFrame = newValue
        
        if self.isEnqueue(currentDate: Date()) { return }
        if let newNextDate = Calendar.current.date(byAdding: .hour, value: newValue, to: self.lastRemovedFromQueue ?? self.createdAt) {
            self.nextTimeInQueue = newNextDate
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Call this function when the card is removed from the queue.
    func removeFromQueue(at removalDate: Date, isSkip: Bool, toArchive: Bool = false) async throws {
        if toArchive {
            
            self.nextTimeInQueue = .distantFuture
            
        } else if isSkip {
            self.skipCount += 1
        }
        // Record the date when the card was removed.
        self.lastRemovedFromQueue = removalDate
        self.timeOnTop = nil
        self.timeInQueue = nil
        self.archived = toArchive
        self.hasBeenFlipped = false
        
        if !toArchive {
            try await updateNextInQueueDate(at: removalDate)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func flipCard() async throws {
        self.hasBeenFlipped = true
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func removeCardFromArchive() async throws {
        self.archived = false
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func toggleIsEssential() async throws {
        self.isEssential.toggle()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func toggleIsDynamic() async throws {
        self.dynamicTimeframe.toggle()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func updateCardType(cardType: CardType) async throws {
        self.cardType = cardType
        WidgetCenter.shared.reloadAllTimelines()
    }
    

    
    var ratingEvents: [RatingEvent] {
        rating.compactMap { dict in
            if let (rating, date) = dict.first {
                return RatingEvent(rating: rating, date: date)
            }
            return nil
        }
    }
    
    var ratingCounts: [RatingCount] {
        let grouped = Dictionary(grouping: ratingEvents, by: { $0.rating })
        return grouped.map { RatingCount(rating: $0.key, count: $0.value.count) }
            .sorted { $0.rating.rawValue < $1.rating.rawValue }
    }
    
    
}



//    var potentialAnswers: [String: Bool] {
//        get {
//            guard let data = potentialAnswersData else { return [:] }
//            return (try? JSONDecoder().decode([String: Bool].self, from: data)) ?? [:]
//        }
//        set {
//            var validatedAnswers = newValue
//
//            // If there are too many answers, only keep the first four.
//            if validatedAnswers.count > 4 {
//                validatedAnswers = Dictionary(uniqueKeysWithValues: Array(validatedAnswers.prefix(4)))
//            }
//
//            // If there are too few, add placeholder answers until there are at least two.
//            while validatedAnswers.count < 2 {
//                // Using an empty string as a key might not be ideal, so you might want to
//                // use a unique placeholder or throw an error in a real-world scenario.
//                validatedAnswers["Answer \(validatedAnswers.count + 1)"] = false
//            }
//
//            potentialAnswersData = try? JSONEncoder().encode(validatedAnswers)
//        }
//    }


//enum ToDo: Identifiable, Codable, Equatable {
//    case task(id: UUID, content: String, isComplete: Bool)
//
//    var id: UUID {
//        switch self {
//        case .task(let id, _, _):
//            return id
//        }
//    }
//
//    var content: String {
//        switch self {
//        case .task(_, let content, _):
//            return content
//        }
//    }
//
//    var isComplete: Bool {
//        get {
//            switch self {
//            case .task(_, _, let isComplete):
//                return isComplete
//            }
//        }
//        set {
//            if case let .task(id, content, _) = self {
//                self = .task(id: id, content: content, isComplete: newValue)
//            }
//        }
//    }
//
//    enum CodingKeys: String, CodingKey {
//        case caseName, id, content, isComplete
//    }
//
//    enum CaseName: String, Codable {
//        case task
//    }
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        switch self {
//        case .task(let id, let content, let isComplete):
//            try container.encode(CaseName.task, forKey: .caseName)
//            try container.encode(id, forKey: .id)
//            try container.encode(content, forKey: .content)
//            try container.encode(isComplete, forKey: .isComplete)
//        }
//    }
//
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        let caseName = try container.decode(CaseName.self, forKey: .caseName)
//        switch caseName {
//        case .task:
//            let id = try container.decode(UUID.self, forKey: .id)
//            let content = try container.decode(String.self, forKey: .content)
//            let isComplete = try container.decode(Bool.self, forKey: .isComplete)
//            self = .task(id: id, content: content, isComplete: isComplete)
//        }
//    }
//}
//
//extension ToDo {
//    static func dummy(content: String, isComplete: Bool = false) -> ToDo {
//        return .task(id: UUID(), content: content, isComplete: isComplete)
//    }
//}



//    /// Adds a new ToDo item with the provided content.
//    func addToDo(content: String) {
//        let newToDo = ToDo.task(id: UUID(), content: content, isComplete: false)
//        self.toDos.append(newToDo)
//        updateAllComplete()
//        WidgetCenter.shared.reloadAllTimelines()
//    }
//
//    /// Deletes a ToDo item identified by its UUID.
//    func deleteToDo(withId id: UUID) {
//        if let index = self.toDos.firstIndex(where: { $0.id == id }) {
//            self.toDos.remove(at: index)
//            updateAllComplete()
//        }
//        WidgetCenter.shared.reloadAllTimelines()
//    }
    
//    /// Marks a specific ToDo item as complete by its UUID.
//    func markToDoComplete(withId id: UUID) {
//        if let index = self.toDos.firstIndex(where: { $0.id == id }) {
//            // Update the ToDo item to be marked as complete.
//            var task = self.toDos[index]
//            task.isComplete = true
//            self.toDos[index] = task
//            updateAllComplete()
//        }
//        WidgetCenter.shared.reloadAllTimelines()
//    }
    
//    func sortToDos() {
//        self.toDos.sort { !$0.isComplete && $1.isComplete }
//        WidgetCenter.shared.reloadAllTimelines()
//    }
    
//    var quizResults: [QuizResult] {
//        isCorrect.compactMap { dict in
//            // Each dictionary is expected to have one key/value pair.
//            if let (result, date) = dict.first {
//                return QuizResult(isCorrect: result, date: date)
//            }
//            return nil
//        }
//    }
//    func submitQuizResult(currentDate: Date, isCorrect: Bool) async throws {
//
//        if self.dynamicTimeframe {
//            if isCorrect {
//                   try  await updateSpacedTimeframe(multiplier: 1.5)
//            } else {
//                try  await updateSpacedTimeframe(multiplier: 0.5)
//            }
//        }
//
//        self.isCorrect.append([isCorrect: currentDate])
//        WidgetCenter.shared.reloadAllTimelines()
//    }
