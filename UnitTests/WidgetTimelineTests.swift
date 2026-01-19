//
//  WidgetTimelineTests.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/15/25.
//

@testable import TopNote


    
import SwiftData
import UIKit
import Foundation
import Testing

// MARK: - Card Entity Conversion Tests

@Suite("CardEntity Conversion Tests")
struct CardEntityConversionTests {
    
    var modelContext: ModelContext
    var modelContainer: ModelContainer
    
    init() throws {
        let schema = Schema([Card.self, Folder.self, CardTag.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(modelContainer)
    }
    
    // MARK: - Basic Conversion Tests
    
    @Test func cardEntityConvertsBasicProperties() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .note,
            priorityTypeRaw: .med,
            content: "Test content",
            answer: nil
        )
        modelContext.insert(card)
        
        let entity = CardEntity(card: card)
        
        #expect(entity.id == card.id)
        #expect(entity.cardTypeRaw == card.cardType.rawValue)
        #expect(entity.content == card.displayContent)
        #expect(entity.isRecurring == card.isRecurring)
    }
    
    @Test func cardEntityConvertsFlashcardWithAnswer() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .none,
            content: "What is Swift?",
            answer: "A programming language"
        )
        modelContext.insert(card)
        
        let entity = CardEntity(card: card)
        
        #expect(entity.cardType == .flashcard)
        #expect(entity.answer == "A programming language")
    }
    
    @Test func cardEntityConvertsTodo() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .high,
            content: "Complete this task",
            answer: nil
        )
        modelContext.insert(card)
        
        let entity = CardEntity(card: card)
        
        #expect(entity.cardType == .todo)
        #expect(entity.content == "Complete this task")
    }
    
    // MARK: - IMAGE DISABLED
    // Image Conversion Tests and Widget Size Variations tests commented out
    /*
    // MARK: - Image Conversion Tests
    
    @Test func cardEntityConvertsWithNoImage() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .note,
            priorityTypeRaw: .none,
            content: "No image card",
            answer: nil
        )
        modelContext.insert(card)
        
        let entity = CardEntity(card: card, widgetImageMaxSize: 600)
        
        #expect(entity.contentImageData == nil)
        #expect(entity.answerImageData == nil)
    }
    
    @Test func cardEntityConvertsContentImage() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .note,
            priorityTypeRaw: .none,
            content: "Card with image",
            answer: nil
        )
        
        // Create test image data
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        let testImage = renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        card.contentImageData = testImage.pngData()
        
        modelContext.insert(card)
        
        let entity = CardEntity(card: card, widgetImageMaxSize: 600)
        
        #expect(entity.contentImageData != nil, "Should have content image data")
        
        if let data = entity.contentImageData {
            let image = UIImage(data: data)
            #expect(image != nil, "Image data should be valid")
        }
    }
    
    @Test func cardEntityConvertsAnswerImage() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .none,
            content: "Question",
            answer: "Answer text"
        )
        
        // Create test image data for answer
        let size = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        let testImage = renderer.image { context in
            UIColor.green.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        card.answerImageData = testImage.pngData()
        
        modelContext.insert(card)
        
        let entity = CardEntity(card: card, widgetImageMaxSize: 600)
        
        #expect(entity.answerImageData != nil, "Should have answer image data")
    }
    
    @Test func cardEntityResizesLargeImage() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .note,
            priorityTypeRaw: .none,
            content: "Large image card",
            answer: nil
        )
        
        // Create a large test image
        let largeSize = CGSize(width: 2000, height: 1500)
        let renderer = UIGraphicsImageRenderer(size: largeSize)
        let largeImage = renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: largeSize))
        }
        card.contentImageData = largeImage.pngData()
        
        modelContext.insert(card)
        
        let maxSize: CGFloat = 600
        let entity = CardEntity(card: card, widgetImageMaxSize: maxSize)
        
        #expect(entity.contentImageData != nil)
        
        if let data = entity.contentImageData,
           let thumbnail = UIImage(data: data) {
            #expect(thumbnail.size.width <= maxSize, "Width should be resized")
            #expect(thumbnail.size.height <= maxSize, "Height should be resized")
        }
    }
    
    @Test func cardEntityHandlesEmptyImageData() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .note,
            priorityTypeRaw: .none,
            content: "Card with empty data",
            answer: nil
        )
        card.contentImageData = Data() // Empty data
        
        modelContext.insert(card)
        
        let entity = CardEntity(card: card, widgetImageMaxSize: 600)
        
        // Should handle gracefully - empty data should result in nil
        #expect(entity.contentImageData == nil, "Empty data should not produce image")
    }
    
    @Test func cardEntityHandlesCorruptedImageData() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .note,
            priorityTypeRaw: .none,
            content: "Card with corrupted data",
            answer: nil
        )
        card.contentImageData = "not an image".data(using: .utf8)
        
        modelContext.insert(card)
        
        let entity = CardEntity(card: card, widgetImageMaxSize: 600)
        
        // Should handle gracefully
        #expect(entity.contentImageData == nil, "Corrupted data should not produce image")
    }
    
    // MARK: - Widget Size Variations
    
    @Test func smallWidgetImageConversion() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .note,
            priorityTypeRaw: .none,
            content: "Small widget",
            answer: nil
        )
        
        let size = CGSize(width: 1000, height: 1000)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.purple.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        card.contentImageData = image.pngData()
        
        modelContext.insert(card)
        
        // Small widget max size
        let entity = CardEntity(card: card, widgetImageMaxSize: 300)
        
        if let data = entity.contentImageData,
           let thumbnail = UIImage(data: data) {
            #expect(thumbnail.size.width <= 300)
            #expect(thumbnail.size.height <= 300)
        }
    }
    
    @Test func largeWidgetImageConversion() throws {
        let card = Card(
            createdAt: Date(),
            cardType: .note,
            priorityTypeRaw: .none,
            content: "Large widget",
            answer: nil
        )
        
        let size = CGSize(width: 2000, height: 2000)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        card.contentImageData = image.pngData()
        
        modelContext.insert(card)
        
        // Large widget max size
        let entity = CardEntity(card: card, widgetImageMaxSize: 900)
        
        if let data = entity.contentImageData,
           let thumbnail = UIImage(data: data) {
            #expect(thumbnail.size.width <= 900)
            #expect(thumbnail.size.height <= 900)
        }
    }
    */
}

// MARK: - CardEntry Creation Tests

@Suite("CardEntry Creation Tests")
struct CardEntryCreationTests {
    
    @Test func cardEntryWithValidCard() throws {
        let entity = CardEntity(
            id: UUID(),
            createdAt: Date(),
            cardTypeRaw: "note",
            content: "Test content",
            answer: nil,
            isRecurring: false,
            skipCount: 0,
            seenCount: 1,
            repeatInterval: 60,
            nextTimeInQueue: Date(),
            folder: nil,
            isArchived: false,
            answerRevealed: false,
            skipEnabled: true,
            tags: nil
        )
        
        let entry = CardEntry(
            date: Date(),
            card: entity,
            queueCardCount: 5,
            totalNumberOfCards: 10,
            nextCardForQueue: entity,
            nextUpdateDate: Date().addingTimeInterval(300),
            selectedCardTypes: [.note, .todo],
            selectedFolders: [],
            widgetIdentifier: "test_widget"
        )
        
        #expect(entry.queueCardCount == 5)
        #expect(entry.totalNumberOfCards == 10)
        #expect(entry.selectedCardTypes.contains(.note))
        #expect(entry.widgetIdentifier == "test_widget")
    }
    
    @Test func cardEntryEmptyQueue() throws {
        let dummyEntity = CardEntity(
            id: UUID(),
            createdAt: Date(),
            cardTypeRaw: "note",
            content: "Dummy",
            answer: nil,
            isRecurring: false,
            skipCount: 0,
            seenCount: 0,
            repeatInterval: 0,
            nextTimeInQueue: Date(),
            folder: nil,
            isArchived: false,
            answerRevealed: false,
            skipEnabled: false,
            tags: nil
        )
        
        let entry = CardEntry(
            date: Date(),
            card: dummyEntity,
            queueCardCount: 0,
            totalNumberOfCards: 5,
            nextCardForQueue: nil,
            nextUpdateDate: Date().addingTimeInterval(3600),
            selectedCardTypes: [.todo],
            selectedFolders: [],
            widgetIdentifier: "empty_queue"
        )
        
        #expect(entry.queueCardCount == 0)
        #expect(entry.totalNumberOfCards == 5)
    }
}

// MARK: - Timeline Behavior Tests

@Suite("Timeline Behavior Tests")
struct TimelineBehaviorTests {
    
    @Test func placeholderEntryExists() throws {
        let entry = placeholderCardEntry(widgetIdentifier: "test_placeholder")
        
        #expect(entry.queueCardCount == 1)
        #expect(entry.widgetIdentifier == "test_placeholder")
    }
    
    @Test func sampleEntryExists() throws {
        let entry = sampleCardEntry(widgetIdentifier: "test_sample")
        
        #expect(entry.queueCardCount == 3)
        #expect(entry.widgetIdentifier == "test_sample")
    }
    
    @Test func errorEntryExists() throws {
        let entry = errorCardEntry(widgetIdentifier: "test_error")
        
        #expect(entry.queueCardCount == 0)
        #expect(entry.card.content == "Unable to load cards.")
    }
}

// MARK: - Widget State Manager Tests

@Suite("Widget State Manager Tests")
struct WidgetStateManagerTests {
    
    @Test func flipStateDefaultsFalse() throws {
        let manager = WidgetStateManager.shared
        let cardID = UUID()
        
        let isFlipped = manager.isFlipped(widgetID: "test", cardID: cardID)
        #expect(isFlipped == false)
    }
    
    @Test func setAndGetFlipState() throws {
        let manager = WidgetStateManager.shared
        let cardID = UUID()
        let widgetID = "test_flip_\(UUID().uuidString)"
        
        manager.setFlipped(true, widgetID: widgetID, cardID: cardID)
        #expect(manager.isFlipped(widgetID: widgetID, cardID: cardID) == true)
        
        manager.setFlipped(false, widgetID: widgetID, cardID: cardID)
        #expect(manager.isFlipped(widgetID: widgetID, cardID: cardID) == false)
    }
    
    @Test func lastCardIDTracking() throws {
        let manager = WidgetStateManager.shared
        let cardID = UUID()
        let widgetID = "test_lastcard_\(UUID().uuidString)"
        
        manager.setLastCardID(cardID, widgetID: widgetID)
        #expect(manager.getLastCardID(widgetID: widgetID) == cardID)
    }
    
    @Test func checkAndResetResetsOnCardChange() throws {
        let manager = WidgetStateManager.shared
        let oldCardID = UUID()
        let newCardID = UUID()
        let widgetID = "test_reset_\(UUID().uuidString)"
        
        // Set state for old card
        manager.setFlipped(true, widgetID: widgetID, cardID: oldCardID)
        manager.setLastCardID(oldCardID, widgetID: widgetID)
        
        // Check and reset for new card
        manager.checkAndResetIfNeeded(widgetID: widgetID, currentCardID: newCardID)
        
        // Old card should be reset
        #expect(manager.isFlipped(widgetID: widgetID, cardID: oldCardID) == false)
        // New card should be tracked
        #expect(manager.getLastCardID(widgetID: widgetID) == newCardID)
    }
}

// MARK: - Multiple Card Processing Tests

@Suite("Multiple Card Processing Tests")
struct MultipleCardProcessingTests {
    
    var modelContext: ModelContext
    var modelContainer: ModelContainer
    
    init() throws {
        let schema = Schema([Card.self, Folder.self, CardTag.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(modelContainer)
    }
    
    @Test func processMultipleCards() throws {
        var cards: [Card] = []
        
        // Create multiple cards
        for i in 0..<5 {
            let card = Card(
                createdAt: Date(),
                cardType: .note,
                priorityTypeRaw: .none,
                content: "Card \(i)",
                answer: nil
            )
            
            modelContext.insert(card)
            cards.append(card)
        }
        
        // Convert all cards to entities
        let entities = cards.map { CardEntity(card: $0) }
        
        #expect(entities.count == 5)
    }
    
    @Test func processCardsWithMixedStates() throws {
        let activeCard = Card(
            createdAt: Date(),
            cardType: .note,
            priorityTypeRaw: .none,
            content: "Active card",
            answer: nil
        )
        
        let archivedCard = Card(
            createdAt: Date(),
            cardType: .note,
            priorityTypeRaw: .none,
            content: "Archived card",
            answer: nil,
            isArchived: true
        )
        
        let flashcard = Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .none,
            content: "Question",
            answer: "Answer"
        )
        
        modelContext.insert(activeCard)
        modelContext.insert(archivedCard)
        modelContext.insert(flashcard)
        
        let entities = [activeCard, archivedCard, flashcard]
            .map { CardEntity(card: $0) }
        
        #expect(entities.count == 3, "All cards should be converted to entities")
        #expect(entities[0].isArchived == false)
        #expect(entities[1].isArchived == true)
        #expect(entities[2].cardType == .flashcard)
    }
}

// MARK: - IMAGE DISABLED
// Image Format Tests commented out
/*
// MARK: - Image Format Tests

@Suite("Image Format Tests")
struct ImageFormatTests {
    
    @Test func pngToJpegConversion() throws {
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.systemPink.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        let pngData = image.pngData()!
        
        // Simulate the makeThumbnailData flow
        let recreated = UIImage(data: pngData)!
        let thumbnail = recreated.widgetThumbnail(maxSize: 600)
        let jpegData = thumbnail.jpegData(compressionQuality: 0.75)
        
        #expect(jpegData != nil, "Should produce JPEG data from PNG source")
        
        if let jpegData = jpegData {
            let finalImage = UIImage(data: jpegData)
            #expect(finalImage != nil, "JPEG data should be valid image")
        }
    }
    
    @Test func jpegToJpegConversion() throws {
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        let jpegData = image.jpegData(compressionQuality: 0.9)!
        
        // Simulate the makeThumbnailData flow
        let recreated = UIImage(data: jpegData)!
        let thumbnail = recreated.widgetThumbnail(maxSize: 600)
        let recompressed = thumbnail.jpegData(compressionQuality: 0.75)
        
        #expect(recompressed != nil, "Should produce JPEG data from JPEG source")
    }
    
    @Test func heicToJpegConversion() throws {
        // HEIC is common on iOS photos - test that we can handle it
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.systemIndigo.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        // We can't easily create HEIC data in tests, but we can verify
        // that our pipeline handles UIImage objects regardless of source format
        let thumbnail = image.widgetThumbnail(maxSize: 600)
        let jpegData = thumbnail.jpegData(compressionQuality: 0.75)
        
        #expect(jpegData != nil, "Should produce JPEG from any UIImage")
    }
}
*/
