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
        let schema = Schema([Card.self, Folder.self])
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
        
        let entity = CardEntity(card: card, widgetImageMaxSize: 600)
        
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
        
        let entity = CardEntity(card: card, widgetImageMaxSize: 600)
        
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
        
        let entity = CardEntity(card: card, widgetImageMaxSize: 600)
        
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
            tags: nil,
            widgetTextHidden: false,
            contentImageData: nil,
            answerImageData: nil
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
    
    @Test func cardEntryWithImages() throws {
        // Create test image data
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let testImage = renderer.image { context in
            UIColor.cyan.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        let imageData = testImage.jpegData(compressionQuality: 0.75)
        
        let entity = CardEntity(
            id: UUID(),
            createdAt: Date(),
            cardTypeRaw: "flashcard",
            content: "Question",
            answer: "Answer",
            isRecurring: true,
            skipCount: 0,
            seenCount: 0,
            repeatInterval: 3600,
            nextTimeInQueue: Date(),
            folder: nil,
            isArchived: false,
            answerRevealed: false,
            skipEnabled: true,
            tags: ["test"],
            widgetTextHidden: false,
            contentImageData: imageData,
            answerImageData: imageData
        )
        
        let entry = CardEntry(
            date: Date(),
            card: entity,
            queueCardCount: 1,
            totalNumberOfCards: 1,
            nextCardForQueue: nil,
            nextUpdateDate: Date().addingTimeInterval(3600),
            selectedCardTypes: [.flashcard],
            selectedFolders: [],
            widgetIdentifier: "test"
        )
        
        #expect(entry.card.contentImageData != nil)
        #expect(entry.card.answerImageData != nil)
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
            tags: nil,
            widgetTextHidden: false,
            contentImageData: nil,
            answerImageData: nil
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
    
    @Test func textHiddenDefaultsFalse() throws {
        let manager = WidgetStateManager.shared
        let cardID = UUID()
        
        let isHidden = manager.isTextHidden(widgetID: "test", cardID: cardID)
        #expect(isHidden == false)
    }
    
    @Test func setAndGetTextHidden() throws {
        let manager = WidgetStateManager.shared
        let cardID = UUID()
        let widgetID = "test_hidden_\(UUID().uuidString)"
        
        manager.setTextHidden(true, widgetID: widgetID, cardID: cardID)
        #expect(manager.isTextHidden(widgetID: widgetID, cardID: cardID) == true)
        
        manager.setTextHidden(false, widgetID: widgetID, cardID: cardID)
        #expect(manager.isTextHidden(widgetID: widgetID, cardID: cardID) == false)
    }
    
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
        let schema = Schema([Card.self, Folder.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(modelContainer)
    }
    
    @Test func processMultipleCardsWithImages() throws {
        var cards: [Card] = []
        
        // Create multiple cards with images
        for i in 0..<5 {
            let card = Card(
                createdAt: Date(),
                cardType: .note,
                priorityTypeRaw: .none,
                content: "Card \(i)",
                answer: nil
            )
            
            let size = CGSize(width: 500, height: 500)
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { context in
                UIColor(
                    red: CGFloat(i) / 5.0,
                    green: 0.5,
                    blue: 1.0 - CGFloat(i) / 5.0,
                    alpha: 1.0
                ).setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }
            card.contentImageData = image.pngData()
            
            modelContext.insert(card)
            cards.append(card)
        }
        
        // Convert all cards to entities
        let entities = cards.map { CardEntity(card: $0, widgetImageMaxSize: 600) }
        
        #expect(entities.count == 5)
        
        // All should have image data
        for entity in entities {
            #expect(entity.contentImageData != nil)
        }
    }
    
    @Test func processCardsWithMixedImageStates() throws {
        let cardWithImage = Card(
            createdAt: Date(),
            cardType: .note,
            priorityTypeRaw: .none,
            content: "Has image",
            answer: nil
        )
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        cardWithImage.contentImageData = image.pngData()
        
        let cardWithoutImage = Card(
            createdAt: Date(),
            cardType: .note,
            priorityTypeRaw: .none,
            content: "No image",
            answer: nil
        )
        
        let cardWithEmptyData = Card(
            createdAt: Date(),
            cardType: .note,
            priorityTypeRaw: .none,
            content: "Empty data",
            answer: nil
        )
        cardWithEmptyData.contentImageData = Data()
        
        modelContext.insert(cardWithImage)
        modelContext.insert(cardWithoutImage)
        modelContext.insert(cardWithEmptyData)
        
        let entities = [cardWithImage, cardWithoutImage, cardWithEmptyData]
            .map { CardEntity(card: $0, widgetImageMaxSize: 600) }
        
        #expect(entities[0].contentImageData != nil, "Card with image should have data")
        #expect(entities[1].contentImageData == nil, "Card without image should have nil")
        #expect(entities[2].contentImageData == nil, "Card with empty data should have nil")
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
