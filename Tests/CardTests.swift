//
//  CardTests.swift
//  TopNoteTests
//
//  Created by [Your Name] on [Date].
//

import Foundation
import Testing
import SwiftData
import WidgetKit
@testable import TopNote


// MARK: - Test Suite for Card

@Suite("Card Model Tests")
struct CardTests {
    
    // MARK: - Creation and Default Values
    
    @Test("Create Card - Default Values")
    func testCreateCardDefaultValues() throws {
        let now = Date()
        let card = Card(
            createdAt: now,
            cardType: .flashCard,
            priorityTypeRaw: .low,
            content: "Test content",
            isEssential: false
        )
        // Verify basic properties.
        #expect(card.createdAt == now)
        #expect(card.content == "Test content")
        #expect(card.cardType == .flashCard)
        #expect(card.priority == .low)
        #expect(card.skipCount == 0)
        #expect(card.seenCount == 0)
        
        // Verify that the URL is constructed correctly.
        let expectedURL = "topnote://card/\(card.id)"
        #expect(card.url.absoluteString == expectedURL)
    }
    
    // MARK: - Update Operations
    
    @Test("Update Card Content")
    func testUpdateCardContent() async throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashCard,
            priorityTypeRaw: .low,
            content: "Old Content"
        )
        try await card.updateCardContent(content: "New Content")
        #expect(card.content == "New Content")
    }
    
    @Test("Update Card Back Content")
    func testUpdateCardBackContent() async throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashCard,
            priorityTypeRaw: .low
        )
        try await card.updateCardBackContent(backContent: "Back Content")
        #expect(card.back == "Back Content")
    }
    
    @Test("Update Priority Value")
    func testUpdatePriorityValue() async throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashCard,
            priorityTypeRaw: .low
        )
        try await card.updatePriorityValue(priority: .high)
        #expect(card.priority == .high)
    }
    
    @Test("Add Card To Queue")
    func testAddCardToQueue() async throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashCard,
            priorityTypeRaw: .low
        )
        let now = Date()
        try await card.addCardToQueue(currentDate: now)
        // The nextTimeInQueue should be set to now.
        #expect(card.nextTimeInQueue == now)
    }
    
    // MARK: - Spaced Timeframe Adjustments
    
    @Test("Update Spaced Timeframe with Multiplier")
    func testUpdateSpacedTimeframe() async throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashCard,
            priorityTypeRaw: .low,
            spacedTimeFrame: 240
        )
        
        // Test multiplier 1.5: 240 * 1.5 = 360.
        try await card.updateSpacedTimeframe(multiplier: 1.5)
        #expect(card.spacedTimeFrame == 360)
        
        // Test multiplier 0.5: 360 * 0.5 = 180.
        try await card.updateSpacedTimeframe(multiplier: 0.5)
        #expect(card.spacedTimeFrame == 180)
        
        // Test lower boundary: new timeframe < 1 should clamp to 1.
        card.spacedTimeFrame = 1
        try await card.updateSpacedTimeframe(multiplier: 0.0)
        #expect(card.spacedTimeFrame == 1)
        
        // Test upper boundary: new timeframe > 8760 should clamp to 8760.
        card.spacedTimeFrame = 9000
        try await card.updateSpacedTimeframe(multiplier: 2.0)
        #expect(card.spacedTimeFrame == 8760)
    }
    
    @Test("Submit Flashcard Rating")
    func testSubmitFlashcardRating() async throws {
        let initialTimeframe = 240
        let card = Card(
            createdAt: Date(),
            cardType: .flashCard,
            priorityTypeRaw: .low,
            spacedTimeFrame: initialTimeframe,
            dynamicTimeframe: true
        )
        let now = Date()
        try await card.submitFlashcardRating(currentDate: now, rating: .good)
        // With .good rating, the multiplier is 1 so spacedTimeFrame remains unchanged.
        #expect(card.spacedTimeFrame == initialTimeframe)
        // Verify that a rating event was appended.
        #expect(card.ratingEvents.count == 1)
        #expect(card.ratingEvents.first?.rating == .good)
    }
    
    @Test("Update Next In Queue Date")
    func testUpdateNextInQueueDate() async throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashCard,
            priorityTypeRaw: .low,
            spacedTimeFrame: 5
        )
        let now = Date()
        try await card.updateNextInQueueDate(at: now)
        let expectedDate = Calendar.current.date(byAdding: .hour, value: 5, to: now)
        #expect(card.nextTimeInQueue == expectedDate)
    }
    
    @Test("Manually Update Spaced TimeFrame", .disabled("Known Bug"))
    func testManuallyUpdateSpacedTimeFrame() async throws {
        let createdAt = Date()
        let card = Card(
            createdAt: createdAt,
            cardType: .flashCard,
            priorityTypeRaw: .low,
            spacedTimeFrame: 240
        )
        // Set a known removal date.
        let removalDate = Calendar.current.date(byAdding: .hour, value: 10, to: createdAt)!
        card.lastRemovedFromQueue = removalDate
        try await card.manuallyUpdateSpacedTimeFrame(newValue: 100)
        // Verify that spacedTimeFrame is updated.
        #expect(card.spacedTimeFrame == 100)
        // Verify that nextTimeInQueue is updated based on lastRemovedFromQueue.
        let expectedDate = Calendar.current.date(byAdding: .hour, value: 110, to: removalDate)
        #expect(card.nextTimeInQueue == expectedDate)
    }
    
    // MARK: - Queue Removal and Card State Operations
    
    @Test("Remove From Queue with Archive")
    func testRemoveFromQueueArchive() async throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashCard,
            priorityTypeRaw: .low
        )
        let removalDate = Date()
        try await card.removeFromQueue(at: removalDate, isSkip: false, toArchive: true)
        #expect(card.archived == true)
        #expect(card.nextTimeInQueue == .distantFuture)
    }
    
    @Test("Remove From Queue with Skip")
    func testRemoveFromQueueSkip() async throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashCard,
            priorityTypeRaw: .low,
            spacedTimeFrame: 240
        )
        let removalDate = Date()
        let previousSkipCount = card.skipCount
        try await card.removeFromQueue(at: removalDate, isSkip: true, toArchive: false)
        #expect(card.skipCount == previousSkipCount + 1)
        // With a skip, spacedTimeFrame is adjusted using a multiplier of 0.5.
        #expect(card.spacedTimeFrame == 120)
        // The nextTimeInQueue should have been updated.
        #expect(card.nextTimeInQueue != removalDate)
    }
    
    @Test("Flip Card")
    func testFlipCard() async throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashCard,
            priorityTypeRaw: .low
        )
        try await card.flipCard()
        #expect(card.hasBeenFlipped == true)
    }
    
    @Test("Remove Card From Archive")
    func testRemoveCardFromArchive() async throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashCard,
            priorityTypeRaw: .low,
            archived: true
        )
        try await card.removeCardFromArchive()
        #expect(card.archived == false)
    }
    
    @Test("Toggle Is Essential")
    func testToggleIsEssential() async throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashCard,
            priorityTypeRaw: .low,
            isEssential: false
        )
        try await card.toggleIsEssential()
        #expect(card.isEssential == true)
    }
    
    @Test("Toggle Dynamic Timeframe")
    func testToggleIsDynamic() async throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashCard,
            priorityTypeRaw: .low,
            dynamicTimeframe: true
        )
        try await card.toggleIsDynamic()
        #expect(card.dynamicTimeframe == false)
    }
    
    @Test("Update Card Type")
    func testUpdateCardType() async throws {
        let card = Card(
            createdAt: Date(),
            cardType: .flashCard,
            priorityTypeRaw: .low
        )
        try await card.updateCardType(cardType: .none)
        #expect(card.cardType == .none)
    }
    
    @Test("Move Card To Folder")
    func testMoveToFolder() async throws {
        let folder = Folder(name: "Test Folder")  // Assuming Folder is defined elsewhere in your project.
        let card = Card(
            createdAt: Date(),
            cardType: .flashCard,
            priorityTypeRaw: .low,
            folder: nil
        )
        try await card.moveToFolder(folder: folder)
        // Using identity check to verify that the folder relationship was updated.
        #expect(card.folder === folder)
    }
}
