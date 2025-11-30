//
//  DemoVideoUITests.swift
//  DemoVideoUITests
//
//  Created by Zachary Sturman on 11/29/25.
//

import XCTest

final class DemoVideoUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["--uitest", "--seed-demo-data"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    @discardableResult
    private func goToFolder(_ identifier: String) -> XCUIElement {
        var element = app.cells[identifier]
        if element.waitForExistence(timeout: 3) {
            element.tap()
            return element
        }

        let folderTitle: String
        switch identifier {
        case "folder_today":
            folderTitle = "Today"
        case "folder_work":
            folderTitle = "Work"
        case "folder_personal":
            folderTitle = "Personal"
        case "folder_reading_list":
            folderTitle = "Reading List"
        default:
            folderTitle = identifier
        }

        element = app.staticTexts[folderTitle]
        if element.waitForExistence(timeout: 5) {
            element.tap()
            return element
        }

        print("⚠️ Folder element not found for identifier \(identifier)")
        return element
    }

    @discardableResult
    private func openCard(_ identifier: String) -> XCUIElement {
        let cardCell = app.cells[identifier]
        if cardCell.waitForExistence(timeout: 5) {
            cardCell.tap()
            return cardCell
        }

        print("⚠️ Card cell not found for identifier \(identifier)")
        return cardCell
    }

    private func goBack() {
        let backButton = app.buttons["backButton"]
        if backButton.exists {
            backButton.tap()
        }
    }

    private func goHome() {
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 1.0)
    }

    @MainActor
    func testVideo1_WidgetCustomization_MultiWidgets() {
        // Navigate folders to ensure they exist and can be tapped
        goToFolder("folder_today")
        goBack()
        goToFolder("folder_work")
        goBack()
        goToFolder("folder_reading_list")
        goBack()

        // Return to Home Screen for widget customization
        goHome()

        // From here, add/configure widgets manually while recording.
        Thread.sleep(forTimeInterval: 3.0)
        // Additional sleeps can be added as needed to allow time for recording
    }

    @MainActor
    func testVideo2_TodoAdaptiveRecurrence() {
        // Navigate to Work folder and open weekly review card
        goToFolder("folder_work")
        openCard("card_plan_weekly_review")

        // Tap recurring button if it exists
        let recurringButton = app.buttons["recurringButton"]
        if recurringButton.exists {
            recurringButton.tap()
        }

        // Tap policies button if it exists
        let policiesButton = app.buttons["policiesButton"]
        if policiesButton.exists {
            policiesButton.tap()
        }

        goBack()
        goBack()

        // Return to Home Screen for widget interactions
        goHome()
    }

    @MainActor
    func testVideo3_NoteWidget_Priorities() {
        // Open notes in Today folder
        goToFolder("folder_today")
        openCard("card_project_kickoff_notes")
        goBack()

        // Open checklist in Personal folder
        goToFolder("folder_personal")
        openCard("card_morning_routine_checklist")
        goBack()

        // Open packing list note
        goToFolder("folder_today")
        openCard("card_vacation_packing_list")
        goBack()

        // Return to Home Screen for widget interactions
        goHome()
    }

    @MainActor
    func testVideo4_FlashcardWidget_SpacedRepetition() {
        // Today folder flashcard
        goToFolder("folder_today")
        openCard("card_what_is_topnote_for")
        let showAnswerButton1 = app.buttons["showAnswerButton"]
        if showAnswerButton1.exists {
            showAnswerButton1.tap()
        }
        goBack()

        // Personal folder flashcard
        goToFolder("folder_personal")
        openCard("card_what_is_spaced_repetition")
        let showAnswerButton2 = app.buttons["showAnswerButton"]
        if showAnswerButton2.exists {
            showAnswerButton2.tap()
        }
        goBack()

        // Return to Home Screen for widget interactions
        goHome()
    }

    @MainActor
    func testVideo5_GetStartedIn30Seconds() {
        // Assume this test demonstrates creating a new note

        // Tap add card button in root list
        let addCardButton = app.buttons["addCardButton"]
        guard addCardButton.waitForExistence(timeout: 5) else {
            print("⚠️ addCardButton not found")
            return
        }
        addCardButton.tap()

        // Select note card type if button exists
        let noteTypeButton = app.buttons["cardType_note"]
        if noteTypeButton.exists {
            noteTypeButton.tap()
        }

        // Enter content text
        let contentTextView = app.textViews["cardContentTextView"]
        guard contentTextView.waitForExistence(timeout: 5) else {
            print("⚠️ cardContentTextView not found")
            return
        }
        contentTextView.tap()
        contentTextView.typeText("Vacation packing list")

        // Choose Today folder via folder picker
        let folderPickerButton = app.buttons["folderPickerButton"]
        if folderPickerButton.exists {
            folderPickerButton.tap()
            let todayFolderCell = app.cells["folder_today"]
            XCTAssertTrue(todayFolderCell.waitForExistence(timeout: 5))
            todayFolderCell.tap()
        }

        // Save the card
        let saveCardButton = app.buttons["saveCardButton"]
        guard saveCardButton.waitForExistence(timeout: 5) else {
            print("⚠️ saveCardButton not found")
            return
        }
        saveCardButton.tap()

        // Optionally verify the new card exists
        let newCardCell = app.cells["card_vacation_packing_list"]
        guard newCardCell.waitForExistence(timeout: 5) else {
            print("⚠️ card_vacation_packing_list not found")
            return
        }

        // Return to Home Screen for widget part
        goHome()
    }

    @MainActor
    func testVideo6_MultiMindsetWidgets() {
        // Work folder: scroll a bit
        goToFolder("folder_work")
        let deepWorkBlock = app.cells["card_deep_work_block"]
        if deepWorkBlock.exists {
            deepWorkBlock.swipeUp()
        }
        let experimentIdeas = app.cells["card_experiment_ideas"]
        if experimentIdeas.exists {
            experimentIdeas.swipeUp()
        }
        goBack()

        // Personal folder: open two cards
        goToFolder("folder_personal")
        openCard("card_call_insurance")
        goBack()
        openCard("card_exercise_plan")
        goBack()

        // Reading list folder: open one card
        goToFolder("folder_reading_list")
        openCard("card_career_goals_outline")
        goBack()

        // Return to Home Screen for combined widgets shot
        goHome()
    }
}
