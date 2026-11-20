//
//  AppStoreScreenshotTests.swift
//  UITests
//
//  Walks the main 2.0 flows against the throwaway in-memory library and saves a screenshot at
//  each step. Set TEST_RUNNER_TOPNOTE_SCREENSHOT_DIR to a folder to keep the PNGs.
//

import XCTest

final class AppStoreScreenshotTests: XCTestCase {
    private var app: XCUIApplication!
    private var outputDirectory: URL? {
        ProcessInfo.processInfo.environment["TOPNOTE_SCREENSHOT_DIR"].map { URL(fileURLWithPath: $0, isDirectory: true) }
    }

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-TopNoteInMemoryStore", "-TopNoteScreenshotData", "-TopNoteSkipSplash", "-TopNoteHideTips", "-TopNoteSkipWelcome"]
    }

    private func snap(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        if let outputDirectory {
            try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
            try? shot.pngRepresentation.write(to: outputDirectory.appendingPathComponent("\(name).png"))
        }
    }

    /// Tabs are a tab bar on iPhone and a top bar or sidebar on iPad.
    private func tab(_ name: String) -> XCUIElement {
        let inTabBar = app.tabBars.buttons[name].firstMatch
        if inTabBar.exists { return inTabBar }
        let button = app.buttons[name].firstMatch
        if button.exists { return button }
        // Landscape iPad shows the tabs as a sidebar.
        return app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", name)).firstMatch
    }

    /// Taps once the element has stopped moving. On iPad hardware the sheet slides as the
    /// keyboard switches between its minimized bar and full size; a person taps what they see.
    private func tapWhenSettled(_ element: XCUIElement, timeout: TimeInterval = 5) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
        var last = element.frame
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            usleep(300_000)
            let current = element.frame
            if current == last { break }
            last = current
        } while Date() < deadline
        element.tap()
    }

    private func chip(_ title: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch
    }

    func testFlowsAndScreenshots() {
        if ProcessInfo.processInfo.environment["TOPNOTE_LANDSCAPE"] == "1" {
            XCUIDevice.shared.orientation = .landscapeLeft
        }
        app.launch()

        // To-do up next
        XCTAssertTrue(app.staticTexts["upNextHeadline"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["todoText"].waitForExistence(timeout: 5))
        snap("01-up-next")

        // Flashcard: flip and see interval previews
        chip("Flashcards").tap()
        XCTAssertTrue(app.staticTexts["flashcardQuestion"].waitForExistence(timeout: 5))
        snap("02-flashcard-question")
        app.buttons["showAnswer"].tap()
        XCTAssertTrue(app.buttons["rate-Good"].waitForExistence(timeout: 5))
        sleep(1)
        snap("03-flashcard-rate")
        let before = app.staticTexts["flashcardQuestion"].label
        app.buttons["rate-Good"].tap()
        XCTAssertTrue(app.buttons["undoButton"].waitForExistence(timeout: 5), "Rating shows an Undo toast")
        sleep(1)
        XCTAssertNotEqual(app.staticTexts["flashcardQuestion"].firstMatch.label, before, "Next flashcard is shown after rating")

        // Note on paper
        chip("Notes").tap()
        XCTAssertTrue(app.staticTexts["noteText"].waitForExistence(timeout: 5))
        sleep(1)
        snap("04-note")
        app.buttons["addThought"].tap()
        let thought = app.textFields["thoughtField"].firstMatch.exists ? app.textFields["thoughtField"] : app.textViews["thoughtField"]
        XCTAssertTrue(thought.waitForExistence(timeout: 5))

        // Capture sheet for each kind
        chip("Notes").tap()
        app.buttons["captureButton"].firstMatch.tap()
        XCTAssertTrue(app.buttons["captureType-note"].waitForExistence(timeout: 5))
        app.buttons["captureType-flashcard"].tap()
        let question = app.textFields["captureText"].firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 5))
        question.tap()
        question.typeText("What does “olvidar” mean?")
        tapWhenSettled(app.textFields["captureAnswer"].firstMatch)
        app.textFields["captureAnswer"].firstMatch.typeText("To forget")
        snap("05-capture-flashcard")
        // On hardware, a tap synthesized milliseconds after synthetic typing can be dropped by the
        // keyboard; a human-length pause (measured: 0.3 s is enough on iPad Pro) avoids that.
        tapWhenSettled(app.buttons["captureSaveAnother"])
        XCTAssertTrue(app.navigationBars["1 added"].waitForExistence(timeout: 5), "Save and add another keeps the sheet open")
        app.buttons["captureType-todo"].tap()
        let task = app.textFields["captureText"].firstMatch
        tapWhenSettled(task)
        task.typeText("Pick up dry cleaning")
        usleep(500_000)
        snap("06-capture-todo")
        tapWhenSettled(app.buttons["captureSave"])
        XCTAssertTrue(app.buttons["captureSave"].waitForNonExistence(timeout: 5), "Save closes the capture sheet")

        // Library still has everything
        tab("Library").tap()
        XCTAssertTrue(app.otherElements["CardListView"].firstMatch.waitForExistence(timeout: 5) || app.collectionViews.firstMatch.waitForExistence(timeout: 5))
        sleep(1)
        snap("07-library")

        // Settings › Reminders
        tab("Settings").tap()
        let remindersRow = app.buttons["settingsReminders"].firstMatch
        if remindersRow.waitForExistence(timeout: 5) {
            remindersRow.tap()
            XCTAssertTrue(app.navigationBars["Reminders"].waitForExistence(timeout: 5))
            snap("08-reminders")
        }
    }

    func testOnboardingAndWhatsNew() {
        app.launchArguments = ["-TopNoteInMemoryStore", "-TopNoteSkipSplash", "-TopNoteHideTips", "-TopNoteShowOnboarding"]
        app.launch()
        XCTAssertTrue(app.buttons["onboardingContinue"].waitForExistence(timeout: 10))
        app.buttons["onboardingContinue"].tap()
        sleep(1)
        snap("09-onboarding-kinds")
        app.buttons["onboardingContinue"].tap()
        XCTAssertTrue(app.buttons["onboardingExamples"].waitForExistence(timeout: 5))
        app.buttons["onboardingExamples"].tap()
        // Examples teach by doing: the first example is now in Up Next.
        XCTAssertTrue(app.staticTexts["upNextHeadline"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["upNextHeadline"].label, "4 cards ready")
    }

    func testWhatsNew() {
        app.launchArguments = ["-TopNoteInMemoryStore", "-TopNoteScreenshotData", "-TopNoteSkipSplash", "-TopNoteHideTips", "-TopNoteShowWhatsNew"]
        app.launch()
        XCTAssertTrue(app.buttons["whatsNewContinue"].waitForExistence(timeout: 10))
        snap("10-whats-new")
        app.buttons["whatsNewContinue"].tap()
        XCTAssertTrue(app.staticTexts["upNextHeadline"].waitForExistence(timeout: 5))
    }
}
