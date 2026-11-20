//
//  RemindersPermissionUITests.swift
//  UITests
//
//  Grants Reminders access on a device so `RemindersSyncTests` can run there. Debug builds only.
//

import XCTest

final class RemindersPermissionUITests: XCTestCase {
    func testGrantRemindersAccess() {
        let app = XCUIApplication()
        app.launchArguments = ["-TopNoteInMemoryStore", "-TopNoteSkipSplash", "-TopNoteSkipWelcome", "-TopNoteHideTips", "-TopNoteRequestRemindersAccess"]
        app.launch()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allow = springboard.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Allow'")).firstMatch
        if allow.waitForExistence(timeout: 8) {
            allow.tap()
        }
        XCTAssertTrue(app.staticTexts["upNextHeadline"].waitForExistence(timeout: 10))
    }
}
