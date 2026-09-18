import XCTest

final class PasswordCrackLabUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func enterAndSubmit(app: XCUIApplication, email: String = "student@example.com", password: String, mode: String) {
        let emailField = app.textFields["email-field"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText(email)

        let passwordField = app.secureTextFields["password-field"]
        passwordField.tap()
        passwordField.typeText(password)

        // A "Save Password?" system prompt can appear after typing into the
        // secure field on the simulator; dismiss it if present so it doesn't
        // block subsequent taps.
        let notNowButton = app.buttons["Not Now"]
        if notNowButton.waitForExistence(timeout: 2) {
            notNowButton.tap()
        }

        let picker = app.buttons["hash-mode-picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.tap()
        let option = app.buttons[mode]
        XCTAssertTrue(option.waitForExistence(timeout: 3), "Expected a menu option labeled \(mode)")
        option.tap()

        let submitButton = app.buttons["submit-button"]
        XCTAssertTrue(submitButton.isEnabled)
        submitButton.tap()

        // iOS can also offer to save the password right after the button
        // tap navigates away from the form; dismiss that instance too.
        if notNowButton.waitForExistence(timeout: 2) {
            notNowButton.tap()
        }
    }

    private func waitForResultBanner(app: XCUIApplication) -> XCUIElement {
        // Query by identifier across any element kind: the banner's exact
        // accessibility element type is an implementation detail of how
        // SwiftUI happens to collapse the view hierarchy.
        let banner = app.descendants(matching: .any).matching(identifier: "result-banner").firstMatch
        XCTAssertTrue(banner.waitForExistence(timeout: 20), "Expected results screen to appear within cracking time caps")
        return banner
    }

    private func tryAgain(app: XCUIApplication) {
        let button = app.buttons["try-again-button"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        // The button can sit just past what XCUITest considers the visible
        // scroll viewport; a coordinate tap avoids flaky "not hittable" retries.
        button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    func testCommonPasswordIsCrackedViaDictionary() throws {
        let app = XCUIApplication()
        app.launch()

        enterAndSubmit(app: app, password: "password123", mode: "SHA-256")
        let banner = waitForResultBanner(app: app)
        XCTAssertTrue(banner.label.contains("EXPOSED"), "Expected a common password to be flagged EXPOSED, got: \(banner.label)")

        tryAgain(app: app)
    }

    func testStrongSlowHashPasswordIsSafe() throws {
        let app = XCUIApplication()
        app.launch()

        enterAndSubmit(app: app, password: "Tr0ub4dor&3xtra!", mode: "Slow hash — PBKDF2 (stand-in for bcrypt/argon2)")
        let banner = waitForResultBanner(app: app)
        XCTAssertTrue(banner.label.contains("SAFE"), "Expected a long, varied, slow-hashed password to be SAFE, got: \(banner.label)")

        tryAgain(app: app)
    }

    func testPasswordReusingEmailIsCrackedViaPersonalInfo() throws {
        let app = XCUIApplication()
        app.launch()

        // The password is exactly the local part of the email, so the
        // email-derived candidate phase should find it before the generic
        // dictionary phase ever runs.
        enterAndSubmit(app: app, email: "midnightrunner@example.com", password: "midnightrunner", mode: "SHA-256")
        let banner = waitForResultBanner(app: app)
        XCTAssertTrue(banner.label.contains("EXPOSED"), "Expected an email-derived password to be EXPOSED, got: \(banner.label)")

        let methodText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "Personal info attack")
        ).firstMatch
        XCTAssertTrue(methodText.waitForExistence(timeout: 5), "Expected the method to be attributed to the email-derived guess")

        tryAgain(app: app)
    }
}
