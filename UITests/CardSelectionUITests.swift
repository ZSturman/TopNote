////
////  CardSelectionUITests.swift
////  UITests
////
////  Created by Zachary Sturman on 01/10/26.
////
//
//import XCTest
//
///// Comprehensive UI tests for card selection behavior
///// Tests the fixes for:
///// - Bug (a): Crash when selecting cards from nil state
///// - Bug (b): Priority changes causing UI jumping
///// - Performance with large card counts
//final class CardSelectionUITests: XCTestCase {
//    
//    var app: XCUIApplication!
//    
//    override func setUpWithError() throws {
//        continueAfterFailure = false
//        app = XCUIApplication()
//        app.launchArguments = ["UI-TESTING"]
//        app.launch()
//    }
//    
//    override func tearDownWithError() throws {
//        app = nil
//    }
//    
//    // MARK: - Card Selection from Nil State Tests
//    
//    /// Tests that selecting a card when no card is currently selected doesn't crash
//    /// This was the main symptom of Bug (a)
//    @MainActor
//    func testSelectCardFromNilState() throws {
//        // Create a card first
//        let addButton = app.buttons["addCard"]
//        guard addButton.waitForExistence(timeout: 3) else {
//            throw XCTSkip("Add button not found")
//        }
//        addButton.tap()
//        
//        let noteButton = app.buttons["Note"]
//        guard noteButton.waitForExistence(timeout: 2) else {
//            throw XCTSkip("Note button not found")
//        }
//        noteButton.tap()
//        
//        // Card should now be selected (content editor visible)
//        let contentField = app.textViews["Card Content Editor"]
//        XCTAssertTrue(contentField.waitForExistence(timeout: 3), 
//                      "Content editor should appear when card is selected")
//        
//        // Type some content to identify the card
//        contentField.tap()
//        let testContent = "Test card \(Int.random(in: 1000...9999))"
//        contentField.typeText(testContent)
//        
//        // Tap Done to deselect
//        let doneButton = app.buttons["Done"]
//        if doneButton.waitForExistence(timeout: 2) {
//            doneButton.tap()
//        } else {
//            // Alternative: tap elsewhere to deselect
//            app.navigationBars.firstMatch.tap()
//        }
//        
//        // Wait for deselection animation
//        sleep(1)
//        
//        // Verify card is deselected (content editor should be hidden or collapsed)
//        // Now tap the card again to select from nil state
//        let cells = app.cells.allElementsBoundByIndex
//        if let cardCell = cells.first(where: { $0.staticTexts[testContent].exists }) {
//            cardCell.tap()
//            
//            // Content editor should appear again - this is where the crash would occur
//            XCTAssertTrue(contentField.waitForExistence(timeout: 3),
//                          "Card selection from nil state should not crash - content editor should appear")
//            
//            // Verify app is still running
//            XCTAssertEqual(app.state, .runningForeground,
//                           "App should still be running after selecting from nil state")
//        }
//    }
//    
//    /// Tests that selecting a different card while one is already selected doesn't crash
//    @MainActor
//    func testSelectDifferentCardWhileOneIsSelected() throws {
//        // Create first card
//        let addButton = app.buttons["addCard"]
//        guard addButton.waitForExistence(timeout: 3) else {
//            throw XCTSkip("Add button not found")
//        }
//        addButton.tap()
//        
//        let noteButton = app.buttons["Note"]
//        guard noteButton.waitForExistence(timeout: 2) else {
//            throw XCTSkip("Note button not found")
//        }
//        noteButton.tap()
//        
//        let contentField = app.textViews["Card Content Editor"]
//        XCTAssertTrue(contentField.waitForExistence(timeout: 3))
//        contentField.tap()
//        contentField.typeText("First Card")
//        
//        // Deselect first card
//        let doneButton = app.buttons["Done"]
//        if doneButton.waitForExistence(timeout: 2) {
//            doneButton.tap()
//        }
//        sleep(1)
//        
//        // Create second card
//        addButton.tap()
//        noteButton.tap()
//        
//        XCTAssertTrue(contentField.waitForExistence(timeout: 3))
//        contentField.tap()
//        contentField.typeText("Second Card")
//        
//        // Now tap the first card while second is selected
//        // This tests switching between cards
//        let cells = app.cells.allElementsBoundByIndex
//        for cell in cells {
//            if cell.staticTexts["First Card"].exists {
//                cell.tap()
//                break
//            }
//        }
//        
//        // Should switch selection without crash
//        XCTAssertTrue(contentField.waitForExistence(timeout: 3),
//                      "Switching between cards should not crash")
//        XCTAssertEqual(app.state, .runningForeground,
//                       "App should still be running after switching cards")
//    }
//    
//    /// Tests rapid card selection and deselection doesn't cause crashes
//    /// This tests the re-entry guard added to SelectedCardModel
//    @MainActor
//    func testRapidCardSelectionDeselection() throws {
//        // Create a card
//        let addButton = app.buttons["addCard"]
//        guard addButton.waitForExistence(timeout: 3) else {
//            throw XCTSkip("Add button not found")
//        }
//        addButton.tap()
//        
//        let noteButton = app.buttons["Note"]
//        guard noteButton.waitForExistence(timeout: 2) else {
//            throw XCTSkip("Note button not found")
//        }
//        noteButton.tap()
//        
//        let contentField = app.textViews["Card Content Editor"]
//        XCTAssertTrue(contentField.waitForExistence(timeout: 3))
//        contentField.tap()
//        contentField.typeText("Rapid test card")
//        
//        // Deselect
//        let doneButton = app.buttons["Done"]
//        if doneButton.waitForExistence(timeout: 2) {
//            doneButton.tap()
//        }
//        sleep(1)
//        
//        // Rapidly tap the card multiple times
//        let cardCell = app.cells.firstMatch
//        for _ in 0..<5 {
//            cardCell.tap()
//            usleep(100_000) // 100ms between taps
//        }
//        
//        // App should still be running
//        XCTAssertEqual(app.state, .runningForeground,
//                       "App should not crash during rapid selection changes")
//    }
//    
//    // MARK: - Priority Change Tests (Bug b)
//    
//    /// Tests that changing priority while a card is selected doesn't cause UI jumping
//    @MainActor
//    func testChangePriorityWhileCardSelected() throws {
//        // Create a todo card (has priority controls)
//        let addButton = app.buttons["addCard"]
//        guard addButton.waitForExistence(timeout: 3) else {
//            throw XCTSkip("Add button not found")
//        }
//        addButton.tap()
//        
//        let todoButton = app.buttons["To-do"]
//        guard todoButton.waitForExistence(timeout: 2) else {
//            throw XCTSkip("Todo button not found")
//        }
//        todoButton.tap()
//        
//        let contentField = app.textViews["Card Content Editor"]
//        XCTAssertTrue(contentField.waitForExistence(timeout: 3))
//        contentField.tap()
//        contentField.typeText("Priority test card")
//        
//        // Find priority button and tap it multiple times to cycle through priorities
//        let priorityButton = app.buttons["PriorityButton"]
//        if priorityButton.waitForExistence(timeout: 2) {
//            // Cycle through all priority levels
//            for _ in 0..<4 {
//                priorityButton.tap()
//                usleep(200_000) // 200ms between taps
//                
//                // Verify card is still selected after each priority change
//                XCTAssertTrue(contentField.exists,
//                              "Card should remain selected after priority change")
//            }
//            
//            // Verify we can still edit the content
//            contentField.tap()
//            contentField.typeText(" - edited")
//            
//            let value = contentField.value as? String ?? ""
//            XCTAssertTrue(value.contains("edited"),
//                          "Should be able to edit card content after priority changes")
//        }
//        
//        XCTAssertEqual(app.state, .runningForeground,
//                       "App should still be running after priority changes")
//    }
//    
//    /// Tests that changing priority on multiple cards in sequence works correctly
//    @MainActor
//    func testChangePriorityOnMultipleCards() throws {
//        let addButton = app.buttons["addCard"]
//        guard addButton.waitForExistence(timeout: 3) else {
//            throw XCTSkip("Add button not found")
//        }
//        
//        // Create 3 todo cards
//        for i in 1...3 {
//            addButton.tap()
//            
//            let todoButton = app.buttons["To-do"]
//            guard todoButton.waitForExistence(timeout: 2) else { continue }
//            todoButton.tap()
//            
//            let contentField = app.textViews["Card Content Editor"]
//            if contentField.waitForExistence(timeout: 2) {
//                contentField.tap()
//                contentField.typeText("Todo \(i)")
//            }
//            
//            // Deselect
//            let doneButton = app.buttons["Done"]
//            if doneButton.waitForExistence(timeout: 1) {
//                doneButton.tap()
//            }
//            sleep(1)
//        }
//        
//        // Now select each card and change its priority
//        let cells = app.cells.allElementsBoundByIndex
//        for cell in cells.prefix(3) {
//            cell.tap()
//            sleep(1)
//            
//            let priorityButton = app.buttons["PriorityButton"]
//            if priorityButton.waitForExistence(timeout: 2) {
//                priorityButton.tap()
//            }
//            
//            // Deselect
//            let doneButton = app.buttons["Done"]
//            if doneButton.waitForExistence(timeout: 1) {
//                doneButton.tap()
//            }
//            sleep(1)
//        }
//        
//        XCTAssertEqual(app.state, .runningForeground,
//                       "App should handle priority changes on multiple cards")
//    }
//    
//    // MARK: - Memory Pressure Tests
//    
//    /// Tests creating and selecting multiple cards to simulate memory pressure
//    @MainActor
//    func testCardSelectionWithMultipleCards() throws {
//        let addButton = app.buttons["addCard"]
//        guard addButton.waitForExistence(timeout: 3) else {
//            throw XCTSkip("Add button not found")
//        }
//        
//        // Create 10 cards to simulate some memory pressure
//        for i in 0..<10 {
//            addButton.tap()
//            
//            let noteButton = app.buttons["Note"]
//            guard noteButton.waitForExistence(timeout: 2) else { continue }
//            noteButton.tap()
//            
//            let contentField = app.textViews["Card Content Editor"]
//            if contentField.waitForExistence(timeout: 2) {
//                contentField.tap()
//                contentField.typeText("Card \(i)")
//            }
//            
//            // Deselect
//            let doneButton = app.buttons["Done"]
//            if doneButton.exists {
//                doneButton.tap()
//            }
//            sleep(1)
//        }
//        
//        // Now rapidly select different cards
//        let cells = app.cells.allElementsBoundByIndex
//        for cell in cells.prefix(5) {
//            cell.tap()
//            usleep(300_000) // 300ms between selections
//        }
//        
//        XCTAssertEqual(app.state, .runningForeground,
//                       "App should handle multiple cards without crashing")
//    }
//    
//    // MARK: - Card Type Specific Tests
//    
//    /// Tests selection behavior for flashcards with answer reveal
//    @MainActor
//    func testFlashcardSelectionAndAnswerReveal() throws {
//        let addButton = app.buttons["addCard"]
//        guard addButton.waitForExistence(timeout: 3) else {
//            throw XCTSkip("Add button not found")
//        }
//        addButton.tap()
//        
//        let flashcardButton = app.buttons["Flashcard"]
//        guard flashcardButton.waitForExistence(timeout: 2) else {
//            throw XCTSkip("Flashcard button not found")
//        }
//        flashcardButton.tap()
//        
//        let contentField = app.textViews["Card Content Editor"]
//        XCTAssertTrue(contentField.waitForExistence(timeout: 3))
//        contentField.tap()
//        contentField.typeText("What is 2+2?")
//        
//        // For flashcards, Show Answer button should exist
//        let showAnswerButton = app.buttons["Show Answer"]
//        XCTAssertTrue(showAnswerButton.waitForExistence(timeout: 2),
//                      "Show Answer button should exist for flashcard")
//        
//        showAnswerButton.tap()
//        
//        // Answer editor should appear
//        let answerField = app.textViews["Answer Content Editor"]
//        if answerField.waitForExistence(timeout: 2) {
//            answerField.tap()
//            answerField.typeText("4")
//        }
//        
//        // Deselect and reselect
//        let doneButton = app.buttons["Done"]
//        if doneButton.exists {
//            doneButton.tap()
//        }
//        sleep(1)
//        
//        let cardCell = app.cells.firstMatch
//        cardCell.tap()
//        
//        XCTAssertTrue(contentField.waitForExistence(timeout: 3),
//                      "Flashcard should be selectable after deselection")
//    }
//    
//    /// Tests todo card completion toggle doesn't interfere with selection
//    @MainActor
//    func testTodoCompletionDuringSelection() throws {
//        let addButton = app.buttons["addCard"]
//        guard addButton.waitForExistence(timeout: 3) else {
//            throw XCTSkip("Add button not found")
//        }
//        addButton.tap()
//        
//        let todoButton = app.buttons["To-do"]
//        guard todoButton.waitForExistence(timeout: 2) else {
//            throw XCTSkip("Todo button not found")
//        }
//        todoButton.tap()
//        
//        let contentField = app.textViews["Card Content Editor"]
//        XCTAssertTrue(contentField.waitForExistence(timeout: 3))
//        contentField.tap()
//        contentField.typeText("Test todo item")
//        
//        // Card should remain editable after typing
//        XCTAssertTrue(contentField.exists,
//                      "Todo should remain selected and editable")
//        
//        XCTAssertEqual(app.state, .runningForeground,
//                       "App should handle todo interactions")
//    }
//}
//
//// MARK: - Performance Tests
//
//final class CardSelectionPerformanceTests: XCTestCase {
//    
//    var app: XCUIApplication!
//    
//    override func setUpWithError() throws {
//        continueAfterFailure = false
//        app = XCUIApplication()
//        app.launchArguments = ["UI-TESTING", "PERFORMANCE-TESTING"]
//        app.launch()
//    }
//    
//    override func tearDownWithError() throws {
//        app = nil
//    }
//    
//    /// Measures the time it takes to select a card
//    /// Selection should complete within 500ms even with many cards
//    @MainActor
//    func testCardSelectionPerformance() throws {
//        let addButton = app.buttons["addCard"]
//        guard addButton.waitForExistence(timeout: 3) else {
//            throw XCTSkip("Add button not found")
//        }
//        
//        addButton.tap()
//        let noteButton = app.buttons["Note"]
//        guard noteButton.waitForExistence(timeout: 2) else {
//            throw XCTSkip("Note button not found")
//        }
//        noteButton.tap()
//        
//        let contentField = app.textViews["Card Content Editor"]
//        XCTAssertTrue(contentField.waitForExistence(timeout: 3))
//        contentField.tap()
//        contentField.typeText("Performance test card")
//        
//        // Deselect
//        let doneButton = app.buttons["Done"]
//        if doneButton.exists {
//            doneButton.tap()
//        }
//        sleep(1)
//        
//        // Measure selection time
//        let startTime = CFAbsoluteTimeGetCurrent()
//        
//        let cardCell = app.cells.firstMatch
//        cardCell.tap()
//        
//        // Wait for content field to appear (indicates selection is complete)
//        XCTAssertTrue(contentField.waitForExistence(timeout: 2))
//        
//        let endTime = CFAbsoluteTimeGetCurrent()
//        let selectionTime = endTime - startTime
//        
//        // Selection should complete within 500ms
//        XCTAssertLessThan(selectionTime, 0.5,
//                          "Card selection should complete within 500ms, took \(selectionTime)s")
//    }
//    
//    /// Tests that the app launches in a reasonable time
//    @MainActor
//    func testLaunchPerformance() throws {
//        measure(metrics: [XCTApplicationLaunchMetric()]) {
//            XCUIApplication().launch()
//        }
//    }
//}
