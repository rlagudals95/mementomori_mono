import XCTest

final class MementoMoriUITests: XCTestCase {
    func testHomeWidgetCanBeAdded() throws { try checkHomeWidget(compact: false) }
    func testSquareWidgetCountsInTwoLines() throws { try checkHomeWidget(compact: true) }

    private func checkHomeWidget(compact: Bool) throws {
        testProfileValidationPersistenceAndClock()
        let app = XCUIApplication(); app.launch()
        XCUIDevice.shared.press(.home)
        let home = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        home.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.65)).press(forDuration: 1.2)
        let edit = home.buttons.matching(NSPredicate(format: "label IN %@", ["Edit", "편집"])).firstMatch
        if edit.waitForExistence(timeout: 2) { edit.tap() }
        let add = home.buttons.matching(NSPredicate(format: "label IN %@", ["Add Widget", "Add Widgets", "위젯 추가", "Add"])).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 5), home.debugDescription)
        add.tap()
        let search = home.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5), home.debugDescription)
        search.tap(); search.typeText("메멘토모리\n")
        let result = home.cells.matching(NSPredicate(format: "label CONTAINS[c] %@ OR label == %@", "memento", "메멘토모리")).firstMatch
        guard result.waitForExistence(timeout: 10) else { XCTFail("Widget gallery did not list MementoMori"); return }
        result.tap()
        if !compact { home.swipeLeft() } // Medium horizontal, or the default small square.
        let addWidget = home.buttons.matching(NSPredicate(format: "label CONTAINS %@ OR label CONTAINS %@", "Add Widget", "위젯 추가")).firstMatch
        XCTAssertTrue(addWidget.waitForExistence(timeout: 5), home.debugDescription)
        addWidget.tap()
        let done = home.buttons.matching(NSPredicate(format: "label IN %@", ["Done", "완료"])).firstMatch
        if done.waitForExistence(timeout: 3) { done.tap() }
        let widget = home.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "유한합니다")).firstMatch
        XCTAssertTrue(widget.waitForExistence(timeout: 15), home.debugDescription)
        let setup = home.staticTexts["앱에서 나의 시간을 설정하세요."]
        XCTAssertFalse(setup.exists, "Saved app profile must appear in widget without separate birthday input")
        let counter = home.otherElements["square-counter"].firstMatch
        let timer = (compact ? counter.staticTexts : home.staticTexts)
            .matching(NSPredicate(format: "label MATCHES %@", "[0-9,]+초")).firstMatch
        XCTAssertTrue(timer.waitForExistence(timeout: 15), home.debugDescription)
        if compact {
            XCTAssertLessThan(counter.frame.width, 200)
            XCTAssertGreaterThan(counter.frame.height, 40, "Two lines should be visibly rendered")
        } else { XCTAssertGreaterThan(timer.frame.width, 200, "Verify the horizontal medium widget") }
        let before = timer.label
        let changes = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", before), object: timer)
        XCTAssertEqual(XCTWaiter.wait(for: [changes], timeout: 8), .completed, "Widget seconds must keep counting")
        let image = XCTAttachment(screenshot: home.screenshot()); image.name = compact ? "Square split seconds widget" : "Home screen widget"; image.lifetime = .keepAlways; self.add(image)
    }

    func testProfileValidationPersistenceAndClock() {
        let app = XCUIApplication()
        app.launch()
        if app.buttons["start"].exists { app.buttons["start"].tap() }
        else { app.buttons["나의 시간 설정"].tap() }
        let birthday = app.textFields["birthday"]
        XCTAssertTrue(birthday.waitForExistence(timeout: 5))
        birthday.tap()
        birthday.press(forDuration: 1)
        if app.menuItems["Select All"].exists { app.menuItems["Select All"].tap() }
        // First launch in a fresh test simulator has no profile.
        let existing = birthday.value as? String ?? ""
        if existing != "YYYY-MM-DD", !existing.isEmpty { birthday.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count)) }
        birthday.typeText("2001-02-29")
        app.swipeUp()
        app.buttons["save-profile"].tap()
        XCTAssertTrue(app.staticTexts["validation-error"].waitForExistence(timeout: 3))
        app.swipeDown()
        birthday.tap()
        birthday.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 10) + "2000-01-01")
        app.swipeUp()
        app.buttons["save-profile"].tap()
        XCTAssertTrue(app.staticTexts["countdown"].waitForExistence(timeout: 5))
        let before = app.staticTexts["countdown"].label
        let changes = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", before), object: app.staticTexts["countdown"])
        XCTAssertEqual(XCTWaiter.wait(for: [changes], timeout: 6), .completed)
        app.terminate(); app.launch()
        XCTAssertTrue(app.staticTexts["countdown"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["start"].exists)
        let image = XCTAttachment(screenshot: app.screenshot()); image.name = "iPhone countdown"; image.lifetime = .keepAlways; add(image)
    }
}
