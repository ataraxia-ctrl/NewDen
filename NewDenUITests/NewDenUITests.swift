import XCTest

final class NewDenUITests: XCTestCase {
    @MainActor
    func testEditCancelUndoAndRelaunch() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["NEWDEN_TEST_STORE"] = UUID().uuidString
        app.launch()
        app.buttons["createPaddy"].tap()
        app.buttons["confirmCreate"].tap()
        XCTAssertTrue(app.buttons["cell-0"].waitForExistence(timeout: 5))
        app.buttons["cell-0"].tap()
        let editor = app.descendants(matching: .any).matching(identifier: "cellText").firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText("My journal")
        app.buttons["saveCell"].tap()
        app.buttons["cell-1"].tap()
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText("First idea")
        app.buttons["saveCell"].tap()
        app.buttons["undo"].tap()
        XCTAssertFalse(app.buttons["cell-1"].label.contains("First idea"))
        app.buttons["redo"].tap()
        XCTAssertTrue(app.buttons["cell-1"].label.contains("First idea"))
        app.buttons["cell-2"].tap()
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText("Discard me")
        app.buttons["キャンセル"].tap()
        XCTAssertFalse(app.buttons["cell-2"].label.contains("Discard me"))
        app.buttons["cell-2"].tap()
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText("Second idea")
        app.buttons["saveCell"].tap()
        app.buttons["cell-3"].tap()
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText("Background draft")
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.buttons["cell-3"].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        app.staticTexts["My journal"].tap()
        XCTAssertTrue(app.buttons["cell-1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["cell-1"].label.contains("First idea"))
        XCTAssertFalse(app.buttons["cell-2"].label.contains("Discard me"))
        XCTAssertTrue(app.buttons["cell-2"].label.contains("Second idea"))
        XCTAssertTrue(app.buttons["cell-3"].label.contains("Background draft"))
        XCTAssertFalse(app.buttons["kindPicker"].isEnabled)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "保存・再起動後の田"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
