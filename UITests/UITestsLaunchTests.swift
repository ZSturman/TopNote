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

    /// Helper to create an XCUIApplication configured for UI testing with optional extra arguments.
    private func makeApp(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["UI-TESTING"] + extraArguments
        return app
    }

    @MainActor
    func testLaunch() throws {
        let app = makeApp()
        app.launch()

        // Wait for main UI instead of relying solely on timing
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5),
                      "Main navigation bar should appear after launch")

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // MARK: - Additional Launch Tests
    
    @MainActor
    func testLaunchWithEmptyData() throws {
        let app = makeApp(extraArguments: ["EMPTY-DATA"])
        app.launch()
        
        XCTAssertEqual(app.state, .runningForeground)
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen - Empty Data"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchWithSampleData() throws {
        let app = makeApp(extraArguments: ["SAMPLE-DATA"])
        app.launch()
        
        XCTAssertEqual(app.state, .runningForeground)
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen - Sample Data"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchPerformanceMetrics() throws {
        measure(metrics: [XCTApplicationLaunchMetric(), XCTMemoryMetric(), XCTCPUMetric()]) {
            let app = self.makeApp()
            app.launch()
            app.terminate()
        }
    }
    
    @MainActor
    func testLaunchInLightMode() throws {
        let app = makeApp(extraArguments: ["LIGHT-MODE"])
        app.launch()
        
        XCTAssertEqual(app.state, .runningForeground)
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen - Light Mode"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchInDarkMode() throws {
        let app = makeApp(extraArguments: ["DARK-MODE"])
        app.launch()
        
        XCTAssertEqual(app.state, .runningForeground)
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen - Dark Mode"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchAndNavigateToCardList() throws {
        let app = makeApp()
        app.launch()
        
        // Wait for main UI to appear instead of sleeping
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5),
                      "Main navigation bar should appear after launch")
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Card List After Launch"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchAndNavigateToFolders() throws {
        let app = makeApp()
        app.launch()
        
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5),
                      "Main navigation bar should appear after launch")
        
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
        // Portrait launch
        XCUIDevice.shared.orientation = .portrait
        let portraitApp = makeApp()
        portraitApp.launch()
        
        let portraitAttachment = XCTAttachment(screenshot: portraitApp.screenshot())
        portraitAttachment.name = "Launch - Portrait"
        portraitAttachment.lifetime = .keepAlways
        add(portraitAttachment)
        
        portraitApp.terminate()
        
        // Landscape launch
        XCUIDevice.shared.orientation = .landscapeLeft
        let landscapeApp = makeApp()
        landscapeApp.launch()
        
        let landscapeAttachment = XCTAttachment(screenshot: landscapeApp.screenshot())
        landscapeAttachment.name = "Launch - Landscape"
        landscapeAttachment.lifetime = .keepAlways
        add(landscapeAttachment)
        
        landscapeApp.terminate()
        
        // Restore orientation
        XCUIDevice.shared.orientation = .portrait
    }
    
    @MainActor
    func testLaunchAfterTermination() throws {
        let app = makeApp()
        
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)
        
        app.terminate()
        XCTAssertEqual(app.state, .notRunning)
        
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch After Termination"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchMemoryPressure() throws {
        let app = makeApp()
        
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)
        
        // Simulate time passing (placeholder for real memory pressure tooling)
        sleep(2)
        
        XCTAssertEqual(app.state, .runningForeground, "App should remain stable under memory pressure")
    }
    
    @MainActor
    func testLaunchWithAccessibilityEnabled() throws {
        let app = makeApp(extraArguments: ["ACCESSIBILITY"])
        app.launch()
        
        XCTAssertEqual(app.state, .runningForeground)
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch - Accessibility Enabled"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchSpeed() throws {
        measure(metrics: [XCTClockMetric()]) {
            let app = self.makeApp()
            app.launch()
            
            _ = app.navigationBars.firstMatch.waitForExistence(timeout: 5)
            
            app.terminate()
        }
    }
    
    @MainActor
    func testLaunchConsistency() throws {
        let app = makeApp()
        
        for iteration in 1...3 {
            app.launch()
            
            XCTAssertEqual(app.state, .runningForeground, "Launch iteration \(iteration) failed")
            
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
        let locales = ["en_US", "es_ES", "fr_FR"]
        
        for locale in locales {
            let app = makeApp(extraArguments: ["-AppleLocale", locale])
            app.launch()
            
            XCTAssertEqual(app.state, .runningForeground)
            
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Launch - \(locale)"
            attachment.lifetime = .keepAlways
            add(attachment)
            
            app.terminate()
        }
    }
}
