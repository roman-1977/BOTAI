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

    func testBOTAIFileImporterPresentsDocumentBrowser() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-botai-ui-testing", "-botai-reset-ui-test-data"]
        app.launch()
        let materials = app.buttons["Материалы"]
        XCTAssertTrue(materials.waitForExistence(timeout: 20))
        materials.tap()
        let add = app.buttons["Добавить материал"]
        XCTAssertTrue(add.waitForExistence(timeout: 10))
        add.tap()
        let importPackage = app.buttons["Импортировать BOTAI"]
        XCTAssertTrue(importPackage.waitForExistence(timeout: 10))
        importPackage.tap()
        let browse = app.buttons["Browse"]
        XCTAssertTrue(browse.waitForExistence(timeout: 10), "The iOS document picker did not appear")
    }

    func testCreateCourseAndCancelEditingKeepsOriginalTitle() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-botai-ui-testing", "-botai-reset-ui-test-data"]
        app.launch()
        let courses = app.buttons["Мои курсы"]
        XCTAssertTrue(courses.waitForExistence(timeout: 20))
        courses.tap()
        XCTAssertTrue(app.navigationBars["Мои курсы"].waitForExistence(timeout: 10))
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Создать курс")).firstMatch.tap()
        let title = app.textFields["ЕГЭ Химия 2027"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        title.tap()
        title.typeText("Курс для проверки")
        app.buttons["Создать"].tap()
        XCTAssertTrue(app.staticTexts["Курс для проверки"].waitForExistence(timeout: 10))
        app.staticTexts["Курс для проверки"].tap()
        let edit = app.buttons.matching(identifier: "Изменить курс").firstMatch
        XCTAssertTrue(edit.waitForExistence(timeout: 10))
        edit.tap()
        let editedTitle = app.textFields["Курс для проверки"]
        XCTAssertTrue(editedTitle.waitForExistence(timeout: 10))
        editedTitle.tap()
        editedTitle.typeText(" новый")
        app.buttons["Отмена"].tap()
        XCTAssertTrue(app.navigationBars["Курс для проверки"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Курс для проверки новый"].exists)
    }

    func testCreateCourseSectionAndTopic() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-botai-ui-testing", "-botai-reset-ui-test-data"]
        app.launch()
        let courses = app.buttons["Мои курсы"]
        XCTAssertTrue(courses.waitForExistence(timeout: 20))
        courses.tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Создать курс")).firstMatch.tap()
        let title = app.textFields["ЕГЭ Химия 2027"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        title.tap()
        title.typeText("Курс с разделом")
        app.buttons["Создать"].tap()
        let course = app.staticTexts["Курс с разделом"]
        XCTAssertTrue(course.waitForExistence(timeout: 10))
        course.tap()
        app.buttons["Добавить раздел"].tap()
        let section = app.textFields["Неорганическая химия"]
        XCTAssertTrue(section.waitForExistence(timeout: 10))
        section.tap()
        section.typeText("Раздел проверки")
        app.buttons["Добавить"].tap()
        let sectionRow = app.staticTexts["Раздел проверки"]
        XCTAssertTrue(sectionRow.waitForExistence(timeout: 10))
        sectionRow.tap()
        app.buttons["Добавить тему"].tap()
        let topic = app.textFields["Например: Кислоты"]
        XCTAssertTrue(topic.waitForExistence(timeout: 10))
        topic.tap()
        topic.typeText("Тема проверки")
        app.buttons["Сохранить"].tap()
        XCTAssertTrue(app.staticTexts["Тема проверки"].waitForExistence(timeout: 10))
    }

    func testSelectBOTAIFileAndImportIntoLibrary() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-botai-ui-testing", "-botai-reset-ui-test-data", "-botai-seed-import-fixture"]
        app.launch()
        XCTAssertTrue(app.buttons["Материалы"].waitForExistence(timeout: 20))
        app.buttons["Материалы"].tap()
        app.buttons["Добавить материал"].tap()
        app.buttons["Импортировать BOTAI"].tap()
        let browse = app.buttons["Browse"]
        XCTAssertTrue(browse.waitForExistence(timeout: 10))
        browse.tap()
        let onDevice = app.cells["On My iPhone"]
        XCTAssertTrue(onDevice.waitForExistence(timeout: 10), app.debugDescription)
        onDevice.tap()
        let appFolder = app.descendants(matching: .any).matching(identifier: "BOTAI, Container").firstMatch
        XCTAssertTrue(appFolder.waitForExistence(timeout: 10), app.debugDescription)
        appFolder.tap()
        let fixture = app.cells.matching(NSPredicate(format: "label CONTAINS %@", "BOTAI-UI-Fixture")).firstMatch
        XCTAssertTrue(fixture.waitForExistence(timeout: 10), app.debugDescription)
        fixture.tap()
        XCTAssertTrue(app.navigationBars["Предпросмотр импорта"].waitForExistence(timeout: 10))
        app.buttons["Добавить в библиотеку"].tap()
        XCTAssertTrue(app.staticTexts["BOTAI UI Fixture"].waitForExistence(timeout: 10))
    }
}
