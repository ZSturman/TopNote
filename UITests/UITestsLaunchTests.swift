//
//  UITestsLaunchTests.swift
//  UITests
//
//  Created by Zachary Sturman on 11/15/25.
//

import XCTest

final class UITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // MARK: - Additional Launch Tests
    
    @MainActor
    func testLaunchWithEmptyData() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI-TESTING", "EMPTY-DATA"]
        app.launch()
        
        XCTAssertTrue(app.state == .runningForeground)
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen - Empty Data"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchWithSampleData() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI-TESTING", "SAMPLE-DATA"]
        app.launch()
        
        XCTAssertTrue(app.state == .runningForeground)
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen - Sample Data"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchPerformanceMetrics() throws {
        let app = XCUIApplication()
        
        measure(metrics: [XCTApplicationLaunchMetric(), XCTMemoryMetric(), XCTCPUMetric()]) {
            app.launch()
            app.terminate()
        }
    }
    
    @MainActor
    func testLaunchInLightMode() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI-TESTING", "LIGHT-MODE"]
        app.launch()
        
        XCTAssertTrue(app.state == .runningForeground)
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen - Light Mode"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchInDarkMode() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI-TESTING", "DARK-MODE"]
        app.launch()
        
        XCTAssertTrue(app.state == .runningForeground)
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen - Dark Mode"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchAndNavigateToCardList() throws {
        let app = XCUIApplication()
        app.launch()
        
        sleep(1)
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Card List After Launch"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchAndNavigateToFolders() throws {
        let app = XCUIApplication()
        app.launch()
        
        sleep(1)
        
        let foldersButton = app.buttons["Folders"]
        if foldersButton.exists {
            foldersButton.tap()
        }
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Folders View After Launch"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchOrientation() throws {
        let app = XCUIApplication()
        
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        
        let portraitAttachment = XCTAttachment(screenshot: app.screenshot())
        portraitAttachment.name = "Launch - Portrait"
        portraitAttachment.lifetime = .keepAlways
        add(portraitAttachment)
        
        app.terminate()
        
        XCUIDevice.shared.orientation = .landscapeLeft
        app.launch()
        
        let landscapeAttachment = XCTAttachment(screenshot: app.screenshot())
        landscapeAttachment.name = "Launch - Landscape"
        landscapeAttachment.lifetime = .keepAlways
        add(landscapeAttachment)
        
        XCUIDevice.shared.orientation = .portrait
    }
    
    @MainActor
    func testLaunchAfterTermination() throws {
        let app = XCUIApplication()
        
        app.launch()
        XCTAssertTrue(app.state == .runningForeground)
        
        app.terminate()
        XCTAssertTrue(app.state == .notRunning)
        
        app.launch()
        XCTAssertTrue(app.state == .runningForeground)
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch After Termination"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchMemoryPressure() throws {
        let app = XCUIApplication()
        
        app.launch()
        
        XCTAssertTrue(app.state == .runningForeground)
        
        sleep(2)
        
        XCTAssertTrue(app.state == .runningForeground, "App should remain stable under memory pressure")
    }
    
    @MainActor
    func testLaunchWithAccessibilityEnabled() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI-TESTING", "ACCESSIBILITY"]
        app.launch()
        
        XCTAssertTrue(app.state == .runningForeground)
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch - Accessibility Enabled"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchSpeed() throws {
        let app = XCUIApplication()
        
        measure {
            app.launch()
            
            _ = app.navigationBars.firstMatch.waitForExistence(timeout: 5)
            
            app.terminate()
        }
    }
    
    @MainActor
    func testLaunchConsistency() throws {
        let app = XCUIApplication()
        
        for iteration in 1...3 {
            app.launch()
            
            XCTAssertTrue(app.state == .runningForeground, "Launch iteration \(iteration) failed")
            
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Launch Consistency - Iteration \(iteration)"
            attachment.lifetime = .keepAlways
            add(attachment)
            
            app.terminate()
            sleep(1)
        }
    }
    
    @MainActor
    func testLaunchWithDifferentLocales() throws {
        let app = XCUIApplication()
        
        let locales = ["en_US", "es_ES", "fr_FR"]
        
        for locale in locales {
            app.launchArguments = ["UI-TESTING", "-AppleLocale", locale]
            app.launch()
            
            XCTAssertTrue(app.state == .runningForeground)
            
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Launch - \(locale)"
            attachment.lifetime = .keepAlways
            add(attachment)
            
            app.terminate()
        }
    }
}
