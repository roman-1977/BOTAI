import XCTest

@MainActor
final class LaunchSmokeTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testFreshLaunchShowsStudyHome() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-botai-ui-testing", "-botai-reset-ui-test-data"]
        app.launch()
        XCTAssertTrue(app.staticTexts["ПЛАН НА СЕГОДНЯ"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts["BOTAI"].exists)
    }

    func testSecondLaunchRetainsIsolatedStorage() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-botai-ui-testing", "-botai-reset-ui-test-data"]
        app.launch()
        XCTAssertTrue(app.staticTexts["ПЛАН НА СЕГОДНЯ"].waitForExistence(timeout: 20))
        app.terminate()
        app.launchArguments = ["-botai-ui-testing"]
        app.launch()
        XCTAssertTrue(app.staticTexts["ПЛАН НА СЕГОДНЯ"].waitForExistence(timeout: 20))
    }

    func testImportSourceOptionsAreAvailable() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-botai-ui-testing", "-botai-reset-ui-test-data"]
        app.launch()
        let materials = app.buttons["Материалы"]
        XCTAssertTrue(materials.waitForExistence(timeout: 20))
        materials.tap()
        let add = app.buttons["Добавить материал"]
        XCTAssertTrue(add.waitForExistence(timeout: 10))
        add.tap()
        let importTable = app.buttons["Импортировать таблицу"]
        let importPackage = app.buttons["Импортировать BOTAI"]
        XCTAssertTrue(importTable.waitForExistence(timeout: 10))
        XCTAssertTrue(importPackage.exists)
        XCTAssertTrue(importPackage.isHittable)
    }

    func testMaterialsLibraryOpens() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-botai-ui-testing", "-botai-reset-ui-test-data"]
        app.launch()
        let materials = app.buttons["Материалы"]
        XCTAssertTrue(materials.waitForExistence(timeout: 20))
        materials.tap()
        XCTAssertTrue(app.staticTexts["ВСЕ МАТЕРИАЛЫ"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Закрыть"].exists)
    }
}
