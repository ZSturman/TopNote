//
//  AppIntent.swift
//  FlashCardWidget
//
//  Created by Zachary Sturman on 2/17/25.
//

import WidgetKit
import AppIntents
import SwiftData

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Top Note Widget"}
    static var description: IntentDescription { "Displays a card from your collection." }


    @Parameter(title: "Show Flashcards", default: true)
    var showFlashCards: Bool
    
    @Parameter(title: "Show Cards with no type", default: true)
    var showNoCardType: Bool

    enum CardType: String, AppEnum {
        case flashCard = "Flash Card"
        case noType = "No Type"

        static var typeDisplayRepresentation: TypeDisplayRepresentation {
            "Card Type"
        }

        static var caseDisplayRepresentations: [CardType: DisplayRepresentation] {
            [
                .flashCard: "Flash Card",
                .noType: "No Type"
            ]
        }
    }
}


//// TODO
//struct ToggleToDoIntent: AppIntent {
//    static var title: LocalizedStringResource = "Toggle To-Do Completion"
//    
//    @Parameter(title: "To-Do ID")
//    var toDoId: String
//    
//    // Explicit initializer to accept a plain String.
//    init(toDoId: String) {
//        self.toDoId = toDoId
//    }
//    
//    init() { }
//    
//    func perform() async throws -> some IntentResult {
//        // Toggle the UserDefaults value.
//        let defaults = UserDefaults.standard
//        var newState: Bool
//        if let current = defaults.object(forKey: toDoId) as? Bool {
//            newState = !current
//            defaults.set(newState, forKey: toDoId)
//        } else {
//            newState = true
//            defaults.set(true, forKey: toDoId)
//        }
//        
//        // Convert the toDoId string to a UUID.
//        guard let uuid = UUID(uuidString: toDoId) else {
//            WidgetCenter.shared.reloadAllTimelines()
//            return .result()
//        }
//        
//        // Open a SwiftData container and update the model.
//        let container = try ModelContainer(for: Card.self)
//        let context = ModelContext(container)
//        
//        // Fetch all cards (or just those of type To Do) and update the matching ToDo.
//        let fetchDescriptor = FetchDescriptor<Card>()
//        let allCards: [Card] = try context.fetch(fetchDescriptor)
//        for card in allCards where card.cardType == .toDo {
//            for i in card.toDos.indices {
//                switch card.toDos[i] {
//                case .task(let id, let content, _) where id == uuid:
//                    // Update the ToDo's isComplete property.
//                    card.toDos[i] = .task(id: id, content: content, isComplete: newState)
//                default:
//                    break
//                }
//            }
//        }
//        
//        try context.save()
//        WidgetCenter.shared.reloadAllTimelines()
//        return .result()
//    }
//}


//struct CompleteAllIntent: AppIntent {
//    static var title: LocalizedStringResource = "Complete All Tasks"
//    
//    func perform() async throws -> some IntentResult {
//        let container = try ModelContainer(for: Card.self)
//        let context = ModelContext(container)
//        let queueManager = QueueManager(context: context)
//        let currentDate = Date()
//        
//        // Remove the top card as a skip action.
//        try await queueManager.removeTopCard(currentDate: currentDate, configuration: ConfigurationAppIntent(), toArchive: true)
//        return .result()
//    }
//}





//
//// QUIZ
//struct SelectAnswerIntent: AppIntent {
//    static var title: LocalizedStringResource = "Select Answer"
//    
//   
//    @Parameter(title: "Selected Answer")
//    var selectedAnswer: String
//    
//    init(selectedAnswer: String) {
//            self.selectedAnswer = selectedAnswer
//        }
//        
//        init() {}
//
//    func perform() async throws -> some IntentResult {
//        // Save the selected answer (e.g. into UserDefaults or a shared container)
//        UserDefaults.standard.set(selectedAnswer, forKey: "selectedAnswer")
//        
//        let potentialAnswers = UserDefaults.standard.dictionary(forKey: "potentialAnswers") as? [String: Bool] ?? [:]
//        let isCorrect = potentialAnswers[selectedAnswer] ?? false
//        UserDefaults.standard.set(isCorrect, forKey: "isAnswerCorrect")
//        
//        let container = try ModelContainer(for: Card.self)
//        let context = ModelContext(container)
//        let queueManager = QueueManager(context: context)
//        
//        // Remove the top card as a skip action.
//        try await queueManager.submitQuizScore(currentDate: Date(), configuration: ConfigurationAppIntent(), isCorrect: isCorrect)
//
//        return .result()
//    }
//}

// RUN NEXT INTENT FOR QUIZ



// FLASHGCARD
struct SubmitFlashcardRatingTypeIntent: AppIntent {
    static var title: LocalizedStringResource = "Difficulty Rating"

    @Parameter(title: "Selected Rating")
    var selectedRating: Int

    init(selectedRating: Int) {
        self.selectedRating = selectedRating
    }

    init() {}

    func perform() async throws -> some IntentResult {

        let container = try ModelContainer(for: Card.self)
        let context = ModelContext(container)
        let queueManager = QueueManager(context: context)
        let currentDate = Date()
        
        // Remove the top card as a skip action.
        try await queueManager.submitFlashcardRating(currentDate: currentDate, configuration: ConfigurationAppIntent(), rating: selectedRating)
        
        return .result()
    }
}



struct ShowFlashcardBackIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Back"
    
    func perform() async throws -> some IntentResult {
        let container = try ModelContainer(for: Card.self)
        let context = ModelContext(container)
        let queueManager = QueueManager(context: context)
        let currentDate = Date()
        
        // Remove the top card as a skip action.
        try await queueManager.showFlashcardBack(currentDate: currentDate, configuration: ConfigurationAppIntent())

        return .result()
    }
}






struct SkipCardIntent: AppIntent {
    static var title: LocalizedStringResource = "Skip Card"
    
    func perform() async throws -> some IntentResult {
        let container = try ModelContainer(for: Card.self)
        let context = ModelContext(container)
        let queueManager = QueueManager(context: context)
        let currentDate = Date()
        
        // Remove the top card as a skip action.
        try await queueManager.removeTopCard(currentDate: currentDate, configuration: ConfigurationAppIntent(), isSkip: true)
        return .result()
    }
}


struct NextCardIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Card"
    
    func perform() async throws -> some IntentResult {
        let container = try ModelContainer(for: Card.self)
        let context = ModelContext(container)
        let queueManager = QueueManager(context: context)
        let currentDate = Date()
        
        // Remove the top card as a "next" action (without incrementing skipCount).
        try await queueManager.removeTopCard(currentDate: currentDate, configuration: ConfigurationAppIntent(), isSkip: false)
        return .result()
    }
}

struct ArchiveCardIntent: AppIntent {
    static var title: LocalizedStringResource = "Archive Card"
    
    func perform() async throws -> some IntentResult {
        let container = try ModelContainer(for: Card.self)
        let context = ModelContext(container)
        let queueManager = QueueManager(context: context)
        let currentDate = Date()
        
        // Remove the top card as a "next" action (without incrementing skipCount).
        try await queueManager.removeTopCard(currentDate: currentDate, configuration: ConfigurationAppIntent(), isSkip: false, toArchive: true)
        return .result()
    }
}
