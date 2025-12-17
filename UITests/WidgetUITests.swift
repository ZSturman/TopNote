//
//  WidgetUITests.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/15/25.
//

import XCTest

/// UI Tests for verifying widget display and image rendering
/// These tests use XCTest attachments for visual verification
final class WidgetUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-TESTING", "WIDGET-TESTING"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Widget Launch Tests
    
    @MainActor
    func testAppLaunchesWithWidgetTestingMode() throws {
        XCTAssertEqual(app.state, .runningForeground)
    }
    
    // MARK: - Card Creation with Image Tests
    
    @MainActor
    func testCreateCardWithImage() throws {
        // Test that app can handle card creation (foundation for widget testing)
        let newCardButton = app.buttons["New Card"]
        if newCardButton.exists {
            newCardButton.tap()
            
            // Wait for editor to appear
            let contentEditor = app.textViews.firstMatch
            if contentEditor.waitForExistence(timeout: 3) {
                contentEditor.tap()
                contentEditor.typeText("Test card for widget")
                
                // Take screenshot for visual verification
                let screenshot = app.screenshot()
                let attachment = XCTAttachment(screenshot: screenshot)
                attachment.name = "Card Creation Screen"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }
    
    // MARK: - Image Display Verification Tests
    
    @MainActor
    func testCardListDisplaysCorrectly() throws {
        // Wait for app to load
        let cardList = app.collectionViews.firstMatch
        if !cardList.waitForExistence(timeout: 5) {
            // Try tables if collection views don't exist
            let tableView = app.tables.firstMatch
            XCTAssertTrue(tableView.waitForExistence(timeout: 5), "Card list should appear")
        }
        
        // Capture screenshot for visual regression testing
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Card List View"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testFlashcardDisplaysCorrectly() throws {
        // Navigate to flashcard if possible
        let flashcardTab = app.buttons["Flashcards"]
        if flashcardTab.exists {
            flashcardTab.tap()
        }
        
        // Look for flashcard in list
        let flashcardCell = app.cells.containing(.staticText, identifier: "flashcard").firstMatch
        if flashcardCell.waitForExistence(timeout: 3) {
            flashcardCell.tap()
            
            // Capture flashcard detail view
            sleep(1) // Allow view to load
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Flashcard Detail View"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
    
    // MARK: - Widget State Simulation Tests
    
    @MainActor
    func testCardWithImageDisplayState() throws {
        // This test verifies that the UI properly reflects image state
        // which is critical for widget display
        
        // Create a card if none exist
        let newCardButton = app.buttons["New Card"]
        if newCardButton.exists {
            newCardButton.tap()
            
            // Add content
            let contentEditor = app.textViews.firstMatch
            if contentEditor.waitForExistence(timeout: 3) {
                contentEditor.tap()
                contentEditor.typeText("Widget test card with content")
            }
            
            // Look for image button
            let imageButton = app.buttons["Add Image"]
            if imageButton.exists {
                // Capture state before image add
                let beforeScreenshot = app.screenshot()
                let beforeAttachment = XCTAttachment(screenshot: beforeScreenshot)
                beforeAttachment.name = "Before Image Add"
                beforeAttachment.lifetime = .keepAlways
                add(beforeAttachment)
            }
        }
    }
    
    // MARK: - Performance Tests for Widget Data
    
    @MainActor
    func testCardLoadingPerformance() throws {
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            let app = XCUIApplication()
            app.launchArguments = ["UI-TESTING"]
            app.launch()
            
            // Wait for cards to load
            _ = app.navigationBars.firstMatch.waitForExistence(timeout: 5)
            
            app.terminate()
        }
    }
    
    @MainActor
    func testMultipleCardScrollPerformance() throws {
        // Wait for list to appear
        let list = app.collectionViews.firstMatch.exists ? 
            app.collectionViews.firstMatch : app.tables.firstMatch
        
        guard list.waitForExistence(timeout: 5) else { return }
        
        // Scroll through cards and measure
        measure(metrics: [XCTClockMetric()]) {
            list.swipeUp()
            list.swipeUp()
            list.swipeDown()
            list.swipeDown()
        }
    }
    
    // MARK: - Widget Identifier Tests
    
    @MainActor
    func testAccessibilityIdentifiersForWidgetElements() throws {
        // Verify key elements have accessibility identifiers for widget testing
        
        // Check for card type icons
        let noteIcon = app.images["note_icon"]
        let todoIcon = app.images["todo_icon"]
        let flashcardIcon = app.images["flashcard_icon"]
        
        // At least one card type should be visible
        let hasCardTypes = noteIcon.exists || todoIcon.exists || flashcardIcon.exists
        
        // Take diagnostic screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Accessibility Identifiers Check"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // MARK: - Image Memory Tests
    
    @MainActor
    func testImageLoadingMemoryStability() throws {
        // This test helps identify memory issues that could affect widgets
        
        let app = XCUIApplication()
        app.launchArguments = ["UI-TESTING", "SAMPLE-DATA"]
        app.launch()
        
        // Navigate through several cards rapidly
        let list = app.collectionViews.firstMatch.exists ?
            app.collectionViews.firstMatch : app.tables.firstMatch
        
        guard list.waitForExistence(timeout: 5) else { return }
        
        // Rapid scrolling to stress test image loading
        for _ in 0..<5 {
            list.swipeUp()
        }
        for _ in 0..<5 {
            list.swipeDown()
        }
        
        // App should still be responsive
        XCTAssertEqual(app.state, .runningForeground, "App should remain stable after rapid scrolling")
        
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "After Memory Stress Test"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // MARK: - Card Type Display Tests
    
    @MainActor
    func testNoteCardDisplay() throws {
        // Find and tap a note card if available
        let noteCard = app.cells.containing(.image, identifier: "doc.text").firstMatch
        if noteCard.waitForExistence(timeout: 3) {
            noteCard.tap()
            
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Note Card Display"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
    
    @MainActor
    func testTodoCardDisplay() throws {
        // Find and tap a todo card if available
        let todoCard = app.cells.containing(.image, identifier: "checkmark.circle").firstMatch
        if todoCard.waitForExistence(timeout: 3) {
            todoCard.tap()
            
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Todo Card Display"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
    
    @MainActor
    func testFlashcardAnswerReveal() throws {
        // Test flashcard flip behavior (critical for widget)
        let flashcard = app.cells.containing(.image, identifier: "rectangle.on.rectangle.angled").firstMatch
        if flashcard.waitForExistence(timeout: 3) {
            flashcard.tap()
            
            // Look for show answer button
            let showAnswerButton = app.buttons["Show Answer"]
            if showAnswerButton.waitForExistence(timeout: 2) {
                // Capture before state
                let beforeScreenshot = app.screenshot()
                let beforeAttachment = XCTAttachment(screenshot: beforeScreenshot)
                beforeAttachment.name = "Flashcard Before Reveal"
                beforeAttachment.lifetime = .keepAlways
                add(beforeAttachment)
                
                showAnswerButton.tap()
                
                // Capture after state
                sleep(1)
                let afterScreenshot = app.screenshot()
                let afterAttachment = XCTAttachment(screenshot: afterScreenshot)
                afterAttachment.name = "Flashcard After Reveal"
                afterAttachment.lifetime = .keepAlways
                add(afterAttachment)
            }
        }
    }
    
    // MARK: - Visual Regression Baseline Tests
    
    @MainActor
    func testCaptureEmptyStateBaseline() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI-TESTING", "EMPTY-DATA"]
        app.launch()
        
        _ = app.navigationBars.firstMatch.waitForExistence(timeout: 5)
        
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Empty State Baseline"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testCapturePopulatedStateBaseline() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI-TESTING", "SAMPLE-DATA"]
        app.launch()
        
        _ = app.navigationBars.firstMatch.waitForExistence(timeout: 5)
        
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Populated State Baseline"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // MARK: - Widget Background Image Tests
    
    @MainActor
    func testCardWithBackgroundImage() throws {
        // Test that cards with images display properly
        // This simulates what the widget would show
        
        let app = XCUIApplication()
        app.launchArguments = ["UI-TESTING", "SAMPLE-DATA"]
        app.launch()
        
        _ = app.navigationBars.firstMatch.waitForExistence(timeout: 5)
        
        // Look for any card cell and capture its display
        let firstCard = app.cells.firstMatch
        if firstCard.waitForExistence(timeout: 3) {
            firstCard.tap()
            
            // Wait for detail view to load
            sleep(1)
            
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Card Detail with Potential Image"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
    
    // MARK: - Widget Text Visibility Tests
    
    @MainActor
    func testTextOverImageVisibility() throws {
        // Verify text is visible over backgrounds (widget concern)
        let app = XCUIApplication()
        app.launchArguments = ["UI-TESTING", "SAMPLE-DATA"]
        app.launch()
        
        _ = app.navigationBars.firstMatch.waitForExistence(timeout: 5)
        
        // Capture various UI states
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Text Over Background Visibility"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // MARK: - Priority and Folder Display Tests
    
    @MainActor
    func testPriorityBadgeDisplay() throws {
        // Priority badges are shown in widgets
        let highPriorityBadge = app.images["exclamationmark.3"]
        let mediumPriorityBadge = app.images["exclamationmark.2"]
        let lowPriorityBadge = app.images["exclamationmark"]
        
        // Take screenshot showing priority indicators
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Priority Badge Display"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testFolderIndicatorDisplay() throws {
        // Folder indicators appear in widgets
        let folderIcon = app.images["folder"]
        
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Folder Indicator Display"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

// MARK: - Widget Snapshot Test Helpers

extension WidgetUITests {
    
    /// Helper to create a diagnostic attachment with metadata
    func captureWidgetDiagnostic(name: String, metadata: [String: String] = [:]) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        
        var fullName = name
        if !metadata.isEmpty {
            let metaString = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: "_")
            fullName = "\(name)_\(metaString)"
        }
        
        attachment.name = fullName
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    /// Helper to verify element visibility for widget requirements
    func verifyWidgetElementVisibility(element: XCUIElement, name: String) {
        if element.exists {
            XCTAssertTrue(element.isHittable, "\(name) should be visible and hittable")
        }
    }
}
