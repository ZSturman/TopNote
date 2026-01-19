////
////  SelectedCardModelTests.swift
////  UnitTests
////
////  Created by Zachary Sturman on 01/10/26.
////
//
//@testable import TopNote
//import SwiftData
//import Foundation
//import Testing
//
//// MARK: - SelectedCardModel Selection Tests
//
//@Suite("SelectedCardModel Selection Tests")
//struct SelectedCardModelSelectionTests {
//    
//    var modelContext: ModelContext
//    var modelContainer: ModelContainer
//    
//    init() throws {
//        let schema = Schema([Card.self, Folder.self, CardTag.self])
//        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
//        modelContainer = try ModelContainer(for: schema, configurations: config)
//        modelContext = ModelContext(modelContainer)
//    }
//    
//    // MARK: - Basic Selection Tests
//    
//    @Test func selectCardFromNilState() throws {
//        let card = Card(
//            createdAt: Date(),
//            cardType: .note,
//            priorityTypeRaw: .none,
//            content: "Test card"
//        )
//        modelContext.insert(card)
//        try modelContext.save()
//        
//        let selectedCardModel = SelectedCardModel()
//        #expect(selectedCardModel.selectedCard == nil)
//        
//        selectedCardModel.selectCard(with: card.id, modelContext: modelContext, isNew: false)
//        
//        #expect(selectedCardModel.selectedCard != nil)
//        #expect(selectedCardModel.selectedCard?.id == card.id)
//        #expect(selectedCardModel.isNewlyCreated == false)
//    }
//    
//    @Test func selectCardAsNewlyCreated() throws {
//        let card = Card(
//            createdAt: Date(),
//            cardType: .todo,
//            priorityTypeRaw: .high,
//            content: "New card"
//        )
//        modelContext.insert(card)
//        try modelContext.save()
//        
//        let selectedCardModel = SelectedCardModel()
//        selectedCardModel.selectCard(with: card.id, modelContext: modelContext, isNew: true)
//        
//        #expect(selectedCardModel.selectedCard?.id == card.id)
//        #expect(selectedCardModel.isNewlyCreated == true)
//    }
//    
//    @Test func selectCardWithUnifiedMethod() throws {
//        let card = Card(
//            createdAt: Date(),
//            cardType: .todo,
//            priorityTypeRaw: .med,
//            content: "Unified method test"
//        )
//        modelContext.insert(card)
//        try modelContext.save()
//        
//        let selectedCardModel = SelectedCardModel()
//        var willSelectCalled = false
//        
//        selectedCardModel.select(
//            card: card,
//            in: modelContext,
//            isNew: false,
//            willSelect: { willSelectCalled = true },
//            willDeselect: nil
//        )
//        
//        #expect(willSelectCalled == true)
//        #expect(selectedCardModel.selectedCard?.id == card.id)
//    }
//    
//    @Test func toggleOffSelectedCard() throws {
//        let card = Card(
//            createdAt: Date(),
//            cardType: .note,
//            priorityTypeRaw: .none,
//            content: "Toggle test"
//        )
//        modelContext.insert(card)
//        try modelContext.save()
//        
//        let selectedCardModel = SelectedCardModel()
//        
//        // First select
//        selectedCardModel.selectCard(with: card.id, modelContext: modelContext)
//        #expect(selectedCardModel.selectedCard != nil)
//        
//        var willDeselectCalled = false
//        
//        // Toggle off by "selecting" same card
//        selectedCardModel.select(
//            card: card,
//            in: modelContext,
//            willDeselect: { willDeselectCalled = true }
//        )
//        
//        #expect(willDeselectCalled == true)
//    }
//    
//    @Test func toggleOffWithDefaultBehavior() throws {
//        let card = Card(
//            createdAt: Date(),
//            cardType: .note,
//            priorityTypeRaw: .none,
//            content: "Toggle default test"
//        )
//        modelContext.insert(card)
//        try modelContext.save()
//        
//        let selectedCardModel = SelectedCardModel()
//        
//        // Select
//        selectedCardModel.selectCard(with: card.id, modelContext: modelContext)
//        #expect(selectedCardModel.selectedCard != nil)
//        
//        // Toggle off with default behavior (no willDeselect callback)
//        selectedCardModel.select(
//            card: card,
//            in: modelContext,
//            willDeselect: nil,
//            saveBeforeDeselect: true
//        )
//        
//        // Should have cleared selection
//        #expect(selectedCardModel.selectedCard == nil)
//    }
//    
//    @Test func switchBetweenCards() throws {
//        let card1 = Card(
//            createdAt: Date(),
//            cardType: .note,
//            priorityTypeRaw: .none,
//            content: "Card 1"
//        )
//        let card2 = Card(
//            createdAt: Date(),
//            cardType: .flashcard,
//            priorityTypeRaw: .high,
//            content: "Card 2",
//            answer: "Answer"
//        )
//        modelContext.insert(card1)
//        modelContext.insert(card2)
//        try modelContext.save()
//        
//        let selectedCardModel = SelectedCardModel()
//        
//        // Select card1
//        selectedCardModel.selectCard(with: card1.id, modelContext: modelContext)
//        #expect(selectedCardModel.selectedCard?.id == card1.id)
//        
//        // Select card2 (should switch, not toggle)
//        var willSelectCalled = false
//        selectedCardModel.select(
//            card: card2,
//            in: modelContext,
//            willSelect: { willSelectCalled = true }
//        )
//        
//        #expect(willSelectCalled == true)
//        #expect(selectedCardModel.selectedCard?.id == card2.id)
//    }
//    
//    @Test func selectNonexistentCard() throws {
//        let fakeID = UUID()
//        let selectedCardModel = SelectedCardModel()
//        
//        selectedCardModel.selectCard(with: fakeID, modelContext: modelContext)
//        
//        #expect(selectedCardModel.selectedCard == nil)
//        #expect(selectedCardModel.isNewlyCreated == false)
//        #expect(selectedCardModel.snapshot == nil)
//    }
//    
//    @Test func clearSelectionResetsAllState() throws {
//        let card = Card(
//            createdAt: Date(),
//            cardType: .note,
//            priorityTypeRaw: .none,
//            content: "Clear test"
//        )
//        modelContext.insert(card)
//        try modelContext.save()
//        
//        let selectedCardModel = SelectedCardModel()
//        
//        selectedCardModel.selectCard(with: card.id, modelContext: modelContext, isNew: true)
//        selectedCardModel.updateDraft(content: "Draft content")
//        selectedCardModel.updateDraft(answer: "Draft answer")
//        selectedCardModel.setDraftCardID(card.id)
//        
//        #expect(selectedCardModel.selectedCard != nil)
//        #expect(selectedCardModel.isNewlyCreated == true)
//        #expect(selectedCardModel.draftContent != nil)
//        
//        selectedCardModel.clearSelection()
//        
//        #expect(selectedCardModel.selectedCard == nil)
//        #expect(selectedCardModel.isNewlyCreated == false)
//        #expect(selectedCardModel.draftContent == nil)
//        #expect(selectedCardModel.draftAnswer == nil)
//        #expect(selectedCardModel.snapshot == nil)
//        #expect(selectedCardModel.draftCardID == nil)
//    }
//}
//
//// MARK: - Snapshot Tests
//
//@Suite("SelectedCardModel Snapshot Tests")
//struct SelectedCardModelSnapshotTests {
//    
//    var modelContext: ModelContext
//    var modelContainer: ModelContainer
//    
//    init() throws {
//        let schema = Schema([Card.self, Folder.self, CardTag.self])
//        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
//        modelContainer = try ModelContainer(for: schema, configurations: config)
//        modelContext = ModelContext(modelContainer)
//    }
//    
//    @Test func snapshotCapturedOnSelection() throws {
//        let card = Card(
//            createdAt: Date(),
//            cardType: .todo,
//            priorityTypeRaw: .high,
//            content: "Snapshot test",
//            repeatInterval: 480
//        )
//        modelContext.insert(card)
//        try modelContext.save()
//        
//        let selectedCardModel = SelectedCardModel()
//        selectedCardModel.selectCard(with: card.id, modelContext: modelContext)
//        
//        #expect(selectedCardModel.snapshot != nil)
//        #expect(selectedCardModel.snapshot?.content == "Snapshot test")
//        #expect(selectedCardModel.snapshot?.priority == .high)
//        #expect(selectedCardModel.snapshot?.repeatInterval == 480)
//    }
//    
//    @Test func snapshotCapturesAllProperties() throws {
//        let folder = Folder(name: "Test Folder")
//        modelContext.insert(folder)
//        
//        let card = Card(
//            createdAt: Date(),
//            cardType: .flashcard,
//            priorityTypeRaw: .med,
//            content: "Question",
//            repeatInterval: 240,
//            answer: "Answer"
//        )
//        card.folder = folder
//        card.isRecurring = true
//        card.skipCount = 5
//        card.seenCount = 10
//        card.isArchived = true
//        card.skipPolicy = .mild
//        card.ratingEasyPolicy = .aggressive
//        card.ratingHardPolicy = .none
//        
//        modelContext.insert(card)
//        try modelContext.save()
//        
//        let selectedCardModel = SelectedCardModel()
//        selectedCardModel.selectCard(with: card.id, modelContext: modelContext)
//        
//        let snapshot = selectedCardModel.snapshot
//        #expect(snapshot != nil)
//        #expect(snapshot?.content == "Question")
//        #expect(snapshot?.answer == "Answer")
//        #expect(snapshot?.priority == .med)
//        #expect(snapshot?.isRecurring == true)
//        #expect(snapshot?.skipCount == 5)
//        #expect(snapshot?.seenCount == 10)
//        #expect(snapshot?.isArchived == true)
//        #expect(snapshot?.skipPolicy == .mild)
//        #expect(snapshot?.ratingEasyPolicy == .aggressive)
//        #expect(snapshot?.ratingHardPolicy == .none)
//        #expect(snapshot?.folder?.id == folder.id)
//    }
//    
//    @Test func snapshotRestoresOriginalValues() throws {
//        let card = Card(
//            createdAt: Date(),
//            cardType: .note,
//            priorityTypeRaw: .low,
//            content: "Original content"
//        )
//        card.isRecurring = false
//        card.repeatInterval = 240
//        
//        modelContext.insert(card)
//        try modelContext.save()
//        
//        let selectedCardModel = SelectedCardModel()
//        selectedCardModel.selectCard(with: card.id, modelContext: modelContext)
//        
//        // Modify the card
//        card.content = "Modified content"
//        card.priority = .high
//        card.isRecurring = true
//        card.repeatInterval = 480
//        
//        #expect(card.content == "Modified content")
//        #expect(card.priority == .high)
//        
//        // Restore from snapshot
//        selectedCardModel.restoreSnapshotIfAvailable()
//        
//        #expect(card.content == "Original content")
//        #expect(card.priority == .low)
//        #expect(card.isRecurring == false)
//        #expect(card.repeatInterval == 240)
//    }
//    
//    @Test func restoreSnapshotDoesNothingWithNoSelection() throws {
//        let selectedCardModel = SelectedCardModel()
//        
//        // Should not crash when called with no selection
//        selectedCardModel.restoreSnapshotIfAvailable()
//        
//        #expect(selectedCardModel.selectedCard == nil)
//        #expect(selectedCardModel.snapshot == nil)
//    }
//    
//    @Test func captureSnapshotUpdatesExisting() throws {
//        let card = Card(
//            createdAt: Date(),
//            cardType: .note,
//            priorityTypeRaw: .none,
//            content: "Initial"
//        )
//        modelContext.insert(card)
//        try modelContext.save()
//        
//        let selectedCardModel = SelectedCardModel()
//        selectedCardModel.selectCard(with: card.id, modelContext: modelContext)
//        
//        #expect(selectedCardModel.snapshot?.content == "Initial")
//        
//        // Modify card and recapture
//        card.content = "Modified"
//        selectedCardModel.captureSnapshot()
//        
//        #expect(selectedCardModel.snapshot?.content == "Modified")
//    }
//}
//
//// MARK: - Draft Management Tests
//
//@Suite("SelectedCardModel Draft Tests")
//struct SelectedCardModelDraftTests {
//    
//    var modelContext: ModelContext
//    var modelContainer: ModelContainer
//    
//    init() throws {
//        let schema = Schema([Card.self, Folder.self, CardTag.self])
//        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
//        modelContainer = try ModelContainer(for: schema, configurations: config)
//        modelContext = ModelContext(modelContainer)
//    }
//    
//    @Test func updateDraftContent() throws {
//        let selectedCardModel = SelectedCardModel()
//        
//        selectedCardModel.updateDraft(content: "Draft content")
//        
//        #expect(selectedCardModel.draftContent == "Draft content")
//    }
//    
//    @Test func updateDraftAnswer() throws {
//        let selectedCardModel = SelectedCardModel()
//        
//        selectedCardModel.updateDraft(answer: "Draft answer")
//        
//        #expect(selectedCardModel.draftAnswer == "Draft answer")
//    }
//    
//    @Test func setDraftCardID() throws {
//        let selectedCardModel = SelectedCardModel()
//        let cardID = UUID()
//        
//        selectedCardModel.setDraftCardID(cardID)
//        
//        #expect(selectedCardModel.draftCardID == cardID)
//    }
//    
//    @Test func clearDraftsRemovesAll() throws {
//        let selectedCardModel = SelectedCardModel()
//        
//        selectedCardModel.updateDraft(content: "Content")
//        selectedCardModel.updateDraft(answer: "Answer")
//        selectedCardModel.setDraftCardID(UUID())
//        
//        selectedCardModel.clearDrafts()
//        
//        #expect(selectedCardModel.draftContent == nil)
//        #expect(selectedCardModel.draftAnswer == nil)
//        #expect(selectedCardModel.draftCardID == nil)
//    }
//    
//    @Test func getDraftsForCardPreventsRaceCondition() throws {
//        let card1 = Card(createdAt: Date(), cardType: .note, priorityTypeRaw: .none, content: "Card 1")
//        let card2 = Card(createdAt: Date(), cardType: .note, priorityTypeRaw: .none, content: "Card 2")
//        modelContext.insert(card1)
//        modelContext.insert(card2)
//        try modelContext.save()
//        
//        let selectedCardModel = SelectedCardModel()
//        
//        // Select card1 and set drafts
//        selectedCardModel.selectCard(with: card1.id, modelContext: modelContext)
//        selectedCardModel.setDraftCardID(card1.id)
//        selectedCardModel.updateDraft(content: "Draft for card 1")
//        selectedCardModel.updateDraft(answer: "Answer for card 1")
//        
//        // Try to get drafts for card2 (should fail - wrong card ID)
//        let draftsForCard2 = selectedCardModel.getDraftsForCard(card2.id)
//        #expect(draftsForCard2 == nil)
//        
//        // Get drafts for card1 (should succeed)
//        let draftsForCard1 = selectedCardModel.getDraftsForCard(card1.id)
//        #expect(draftsForCard1 != nil)
//        #expect(draftsForCard1?.content == "Draft for card 1")
//        #expect(draftsForCard1?.answer == "Answer for card 1")
//    }
//    
//    @Test func getDraftsForCardWithNoDraftID() throws {
//        let card = Card(createdAt: Date(), cardType: .note, priorityTypeRaw: .none, content: "Test")
//        modelContext.insert(card)
//        try modelContext.save()
//        
//        let selectedCardModel = SelectedCardModel()
//        
//        // Set drafts but don't set draft card ID
//        selectedCardModel.updateDraft(content: "Some content")
//        
//        // Should return nil because draftCardID doesn't match
//        let drafts = selectedCardModel.getDraftsForCard(card.id)
//        #expect(drafts == nil)
//    }
//    
//    @Test func draftsAreClearedOnSelection() throws {
//        let card = Card(createdAt: Date(), cardType: .note, priorityTypeRaw: .none, content: "Test")
//        modelContext.insert(card)
//        try modelContext.save()
//        
//        let selectedCardModel = SelectedCardModel()
//        
//        // Set some drafts
//        selectedCardModel.updateDraft(content: "Old draft")
//        selectedCardModel.setDraftCardID(UUID()) // Different card
//        
//        // Select a card - should clear drafts
//        selectedCardModel.selectCard(with: card.id, modelContext: modelContext)
//        
//        #expect(selectedCardModel.draftContent == nil)
//        #expect(selectedCardModel.draftAnswer == nil)
//        #expect(selectedCardModel.draftCardID == nil)
//    }
//}
//
//// MARK: - Performance Tests
//
//@Suite("Card Selection Performance Tests")
//struct CardSelectionPerformanceTests {
//    
//    var modelContext: ModelContext
//    var modelContainer: ModelContainer
//    
//    init() throws {
//        let schema = Schema([Card.self, Folder.self, CardTag.self])
//        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
//        modelContainer = try ModelContainer(for: schema, configurations: config)
//        modelContext = ModelContext(modelContainer)
//    }
//    
//    @Test func selectCardWithManyCardsInContext() throws {
//        // Create 100 cards to simulate moderate load
//        for i in 0..<100 {
//            let card = Card(
//                createdAt: Date().addingTimeInterval(TimeInterval(-i * 3600)),
//                cardType: [.note, .todo, .flashcard][i % 3],
//                priorityTypeRaw: [.none, .low, .med, .high][i % 4],
//                content: "Card number \(i)"
//            )
//            modelContext.insert(card)
//        }
//        try modelContext.save()
//        
//        // Fetch all cards
//        let descriptor = FetchDescriptor<Card>()
//        let cards = try modelContext.fetch(descriptor)
//        #expect(cards.count == 100)
//        
//        // Select a card and measure it doesn't take too long
//        let selectedCardModel = SelectedCardModel()
//        let targetCard = cards[50]
//        
//        let startTime = CFAbsoluteTimeGetCurrent()
//        selectedCardModel.selectCard(with: targetCard.id, modelContext: modelContext)
//        let endTime = CFAbsoluteTimeGetCurrent()
//        
//        #expect(selectedCardModel.selectedCard?.id == targetCard.id)
//        
//        // Selection should complete quickly (under 100ms)
//        let selectionTime = endTime - startTime
//        #expect(selectionTime < 0.1, "Selection should complete in under 100ms, took \(selectionTime)s")
//    }
//    
//    @Test func rapidSelectionChanges() throws {
//        // Create several cards
//        var cards: [Card] = []
//        for i in 0..<10 {
//            let card = Card(
//                createdAt: Date(),
//                cardType: .note,
//                priorityTypeRaw: .none,
//                content: "Card \(i)"
//            )
//            modelContext.insert(card)
//            cards.append(card)
//        }
//        try modelContext.save()
//        
//        let selectedCardModel = SelectedCardModel()
//        
//        // Rapidly switch between cards
//        let startTime = CFAbsoluteTimeGetCurrent()
//        for card in cards {
//            selectedCardModel.select(
//                card: card,
//                in: modelContext,
//                willSelect: nil,
//                willDeselect: nil
//            )
//        }
//        let endTime = CFAbsoluteTimeGetCurrent()
//        
//        // Should handle 10 rapid selections quickly
//        let totalTime = endTime - startTime
//        #expect(totalTime < 0.5, "10 rapid selections should complete in under 500ms, took \(totalTime)s")
//        
//        // Should end with last card selected
//        #expect(selectedCardModel.selectedCard?.id == cards.last?.id)
//    }
//    
//    @Test func selectCardWithManyTags() throws {
//        // Create card with many tags
//        let card = Card(
//            createdAt: Date(),
//            cardType: .note,
//            priorityTypeRaw: .none,
//            content: "Tagged card"
//        )
//        modelContext.insert(card)
//        
//        // Add 20 tags
//        var tags: [CardTag] = []
//        for i in 0..<20 {
//            let tag = CardTag(name: "Tag \(i)")
//            modelContext.insert(tag)
//            tags.append(tag)
//        }
//        card.tags = tags
//        
//        try modelContext.save()
//        
//        let selectedCardModel = SelectedCardModel()
//        
//        let startTime = CFAbsoluteTimeGetCurrent()
//        selectedCardModel.selectCard(with: card.id, modelContext: modelContext)
//        let endTime = CFAbsoluteTimeGetCurrent()
//        
//        #expect(selectedCardModel.selectedCard?.id == card.id)
//        #expect(selectedCardModel.snapshot?.tags.count == 20)
//        
//        // Should still be fast with many tags
//        let selectionTime = endTime - startTime
//        #expect(selectionTime < 0.1, "Selection with many tags should be fast, took \(selectionTime)s")
//    }
//}
//
//// MARK: - CardSnapshot Tests
//
//@Suite("CardSnapshot Tests")
//struct CardSnapshotTests {
//    
//    var modelContext: ModelContext
//    var modelContainer: ModelContainer
//    
//    init() throws {
//        let schema = Schema([Card.self, Folder.self, CardTag.self])
//        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
//        modelContainer = try ModelContainer(for: schema, configurations: config)
//        modelContext = ModelContext(modelContainer)
//    }
//    
//    @Test func snapshotInitializationCapturesAllFields() throws {
//        let folder = Folder(name: "Test")
//        modelContext.insert(folder)
//        
//        let tag1 = CardTag(name: "Tag1")
//        let tag2 = CardTag(name: "Tag2")
//        modelContext.insert(tag1)
//        modelContext.insert(tag2)
//        
//        let card = Card(
//            createdAt: Date(),
//            cardType: .flashcard,
//            priorityTypeRaw: .high,
//            content: "Question",
//            repeatInterval: 720,
//            initialRepeatInterval: 720,
//            answer: "Answer"
//        )
//        card.folder = folder
//        card.tags = [tag1, tag2]
//        card.isRecurring = true
//        card.skipCount = 3
//        card.seenCount = 7
//        card.isArchived = false
//        card.answerRevealed = true
//        card.skipPolicy = .aggressive
//        card.ratingEasyPolicy = .mild
//        card.ratingMedPolicy = .none
//        card.ratingHardPolicy = .aggressive
//        card.isComplete = false
//        card.resetRepeatIntervalOnComplete = true
//        card.skipEnabled = true
//        
//        modelContext.insert(card)
//        try modelContext.save()
//        
//        let snapshot = CardSnapshot(from: card)
//        
//        #expect(snapshot.content == "Question")
//        #expect(snapshot.answer == "Answer")
//        #expect(snapshot.priority == .high)
//        #expect(snapshot.isRecurring == true)
//        #expect(snapshot.skipCount == 3)
//        #expect(snapshot.seenCount == 7)
//        #expect(snapshot.repeatInterval == 720)
//        #expect(snapshot.initialRepeatInterval == 720)
//        #expect(snapshot.folder?.id == folder.id)
//        #expect(snapshot.tags.count == 2)
//        #expect(snapshot.isArchived == false)
//        #expect(snapshot.answerRevealed == true)
//        #expect(snapshot.skipPolicy == .aggressive)
//        #expect(snapshot.ratingEasyPolicy == .mild)
//        #expect(snapshot.ratingMedPolicy == .none)
//        #expect(snapshot.ratingHardPolicy == .aggressive)
//        #expect(snapshot.isComplete == false)
//        #expect(snapshot.resetRepeatIntervalOnComplete == true)
//        #expect(snapshot.skipEnabled == true)
//    }
//    
//    @Test func snapshotApplyRestoresAllFields() throws {
//        let card = Card(
//            createdAt: Date(),
//            cardType: .todo,
//            priorityTypeRaw: .none,
//            content: "Original"
//        )
//        card.isRecurring = false
//        card.skipCount = 0
//        card.seenCount = 0
//        card.priority = .none
//        
//        modelContext.insert(card)
//        try modelContext.save()
//        
//        // Capture snapshot
//        let snapshot = CardSnapshot(from: card)
//        
//        // Modify everything
//        card.content = "Modified"
//        card.priority = .high
//        card.isRecurring = true
//        card.skipCount = 10
//        card.seenCount = 20
//        card.isArchived = true
//        
//        // Apply snapshot
//        snapshot.apply(to: card)
//        
//        // Verify restoration
//        #expect(card.content == "Original")
//        #expect(card.priority == .none)
//        #expect(card.isRecurring == false)
//        #expect(card.skipCount == 0)
//        #expect(card.seenCount == 0)
//        #expect(card.isArchived == false)
//    }
//}
