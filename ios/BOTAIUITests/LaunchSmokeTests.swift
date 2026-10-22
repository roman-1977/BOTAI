import XCTest

@MainActor
final class LaunchSmokeTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testExtendedPDFReportOpensSystemShareSheet() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-botai-ui-testing", "-botai-reset-ui-test-data"]
        app.launch()
        let report = app.buttons["Расширенный отчёт · PDF"]
        XCTAssertTrue(report.waitForExistence(timeout: 20))
        if !report.isHittable { app.swipeUp() }
        report.tap()
        XCTAssertFalse(app.alerts["Не удалось создать PDF"].exists)
        // The share sheet is hosted by UIActivityViewController, not a custom preview.
        XCTAssertTrue(app.otherElements["ActivityListView"].waitForExistence(timeout: 12)
            || app.buttons["Закрыть"].exists
            || app.buttons["Close"].exists
            || app.staticTexts["Copy"].exists)
        captureScreen(app, name: "05-Extended-PDF-Share")
    }

    func testFreshLaunchShowsStudyHome() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-botai-ui-testing", "-botai-reset-ui-test-data"]
        app.launch()
        XCTAssertTrue(app.staticTexts["ПЛАН НА СЕГОДНЯ"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts["BOTAI"].exists)
    }

    func testPrimaryScreensVisualBaseline() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-botai-ui-testing", "-botai-reset-ui-test-data"]
        app.launch()
        XCTAssertTrue(app.staticTexts["ПЛАН НА СЕГОДНЯ"].waitForExistence(timeout: 20))
        captureScreen(app, name: "01-Home")

        app.buttons["Мои курсы"].tap()
        XCTAssertTrue(app.navigationBars["Мои курсы"].waitForExistence(timeout: 10))
        captureScreen(app, name: "02-Courses")
        app.buttons["Закрыть"].tap()

        app.buttons["Материалы"].tap()
        XCTAssertTrue(app.staticTexts["ВСЕ МАТЕРИАЛЫ"].waitForExistence(timeout: 10))
        captureScreen(app, name: "03-Materials")
        app.buttons["Закрыть"].tap()

        app.buttons["Профиль"].tap()
        XCTAssertTrue(app.navigationBars["Профиль"].waitForExistence(timeout: 10))
        captureScreen(app, name: "04-Profile")
    }

    private func captureScreen(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
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

    func testCancelSectionEditingKeepsOriginalTitleAfterRelaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-botai-ui-testing", "-botai-reset-ui-test-data"]
        app.launch()
        XCTAssertTrue(app.buttons["Мои курсы"].waitForExistence(timeout: 20))
        app.buttons["Мои курсы"].tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Создать курс")).firstMatch.tap()
        let title = app.textFields["ЕГЭ Химия 2027"]
        title.tap()
        title.typeText("Курс разделов")
        app.buttons["Создать"].tap()
        app.staticTexts["Курс разделов"].tap()
        app.buttons["Добавить раздел"].tap()
        let section = app.textFields["Неорганическая химия"]
        section.tap()
        section.typeText("Исходный раздел")
        app.buttons["Добавить"].tap()
        XCTAssertTrue(app.staticTexts["Исходный раздел"].waitForExistence(timeout: 10))
        app.staticTexts["Исходный раздел"].tap()
        app.buttons["Изменить раздел"].tap()
        let edited = app.textFields["Исходный раздел"]
        XCTAssertTrue(edited.waitForExistence(timeout: 10))
        edited.tap()
        edited.typeText(" изменён")
        app.buttons["Отмена"].tap()
        XCTAssertTrue(app.staticTexts["Исходный раздел"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Исходный раздел изменён"].exists)
        app.terminate()
        app.launchArguments = ["-botai-ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["Мои курсы"].waitForExistence(timeout: 20))
        app.buttons["Мои курсы"].tap()
        app.staticTexts["Курс разделов"].tap()
        XCTAssertTrue(app.staticTexts["Исходный раздел"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Исходный раздел изменён"].exists)
    }

    func testCreateCourseSectionTopicAndGoal() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-botai-ui-testing", "-botai-reset-ui-test-data", "-botai-seed-course-material"]
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
        let topicRow = app.staticTexts["Тема проверки"]
        XCTAssertTrue(topicRow.waitForExistence(timeout: 10))
        topicRow.tap()
        app.buttons["Выбрать опросники"].tap()
        XCTAssertTrue(app.staticTexts["Учебный материал UI"].waitForExistence(timeout: 10))
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "course-rule-")).firstMatch.tap()
        app.buttons["Готово"].tap()
        app.navigationBars["Тема проверки"].buttons.firstMatch.tap()
        app.navigationBars["Раздел"].buttons.firstMatch.tap()
        app.buttons["Цели"].tap()
        app.buttons["Добавить цель"].tap()
        let goal = app.textFields["Например: Выучить кислоты"]
        XCTAssertTrue(goal.waitForExistence(timeout: 10))
        goal.tap()
        goal.typeText("Освоить проверку")
        app.buttons["Выбрать из курса"].tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Раздел проверки")).firstMatch.tap()
        app.buttons["Готово"].tap()
        app.buttons["Создать"].tap()
        XCTAssertTrue(app.staticTexts["Освоить проверку"].waitForExistence(timeout: 10))
        app.buttons["Начать"].tap()
        XCTAssertTrue(app.staticTexts["Активная"].waitForExistence(timeout: 10))
        app.buttons["Пауза"].tap()
        XCTAssertTrue(app.staticTexts["На паузе"].waitForExistence(timeout: 10))
        app.buttons["Продолжить"].tap()
        XCTAssertTrue(app.staticTexts["Активная"].waitForExistence(timeout: 10))
        app.terminate()
        app.launchArguments = ["-botai-ui-testing"]
        app.launch()
        let reopenedCourses = app.buttons["Мои курсы"]
        XCTAssertTrue(reopenedCourses.waitForExistence(timeout: 20))
        reopenedCourses.tap()
        let reopenedCourse = app.staticTexts["Курс с разделом"]
        XCTAssertTrue(reopenedCourse.waitForExistence(timeout: 10))
        reopenedCourse.tap()
        app.buttons["Цели"].tap()
        XCTAssertTrue(app.staticTexts["Освоить проверку"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Активная"].waitForExistence(timeout: 10))
        app.navigationBars["Курс с разделом"].buttons.firstMatch.tap()
        app.navigationBars["Мои курсы"].buttons.firstMatch.tap()
        let launch = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "УЧИТЬСЯ СЕГОДНЯ")).firstMatch
        XCTAssertTrue(launch.waitForExistence(timeout: 10))
        launch.tap()
        XCTAssertTrue(app.staticTexts["Кислота"].waitForExistence(timeout: 10))
        app.staticTexts["Кислота"].tap()
        let answer = app.buttons["ОТВЕТИЛ ЛЕГКО"]
        XCTAssertTrue(answer.waitForExistence(timeout: 10))
        answer.tap()
        XCTAssertTrue(app.staticTexts["ВОПРОСЫ ЗАКОНЧИЛИСЬ"].waitForExistence(timeout: 10))
        app.buttons["ГОТОВО"].tap()
        app.buttons["Материалы"].tap()
        XCTAssertTrue(app.staticTexts["Учебный материал UI"].waitForExistence(timeout: 10))
        app.buttons["Меню сохранённого материала"].tap()
        app.buttons["Удалить из библиотеки"].tap()
        app.buttons["Удалить материал"].tap()
        XCTAssertFalse(app.staticTexts["Учебный материал UI"].waitForExistence(timeout: 3))
        app.buttons["Закрыть"].tap()
        app.buttons["Мои курсы"].tap()
        app.staticTexts["Курс с разделом"].tap()
        app.buttons["Цели"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "0 опросников")).firstMatch.waitForExistence(timeout: 10))
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
import XCTest

/// Runs against a dedicated simulator's BOTAI-UITests database seeded by the
/// chemistry pilot script. Do not run this test on an unseeded simulator.
@MainActor
final class ChemistryPilotSmokeTests: XCTestCase {
    func testSeededChemistryCourseAndGoalAreVisible() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-botai-ui-testing"]
        app.launch()
        XCTAssertTrue(app.staticTexts["ПЛАН НА СЕГОДНЯ"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["Мои курсы"].waitForExistence(timeout: 10))
        app.buttons["Мои курсы"].tap()
        XCTAssertTrue(app.staticTexts["ЕГЭ — Химия 2027"].waitForExistence(timeout: 15))
        app.staticTexts["ЕГЭ — Химия 2027"].tap()
        XCTAssertTrue(app.staticTexts["5 разделов"].waitForExistence(timeout: 10))
        app.buttons["Цели"].tap()
        XCTAssertTrue(app.staticTexts["Освоить 90% химии к 31 декабря"].waitForExistence(timeout: 10))
    }
}
