//
//  UltimatePortfolioUITests.swift
//  UltimatePortfolioUITests
//
//  Created by Kevin Heredia on 29/4/25.
//

import XCTest

// Extensión para limpiar el contenido de un campo de texto.
extension XCUIElement {
    func clear() {
        guard let stringValue = self.value as? String else {
            XCTFail("Failed to clear text in XCUIElement")
            return
        }
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }
}

final class UltimatePortfolioUITests: XCTestCase {
    var app: XCUIApplication!

    // Configura la app para pruebas con argumentos de testing antes de cada test.
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["enable-testing"]
        app.launch()
    }
    
    // Verifica que la app muestra una barra de navegación al iniciar.
    func testAppStartsWithNavigationBar() throws {
        XCTAssertTrue(app.navigationBars.element.exists, "There should be a navigation bar when the app launches.")
    }
    
    // Comprueba que los botones principales están presentes al iniciar.
    func testAppHasBasicButtonsOnLaunch() throws {
        XCTAssertTrue(app.navigationBars.buttons["Filters"].exists, "There should be a Filters button on launch.")
        XCTAssertTrue(app.navigationBars.buttons["Filter"].exists, "There should be a Filters button on launch.")
        XCTAssertTrue(app.navigationBars.buttons["New issue"].exists, "There should be a Filters button on launch.")
    }

    // Asegura que la lista comienza vacía sin elementos.
    func testNoIssuesAtStart() {
        XCTAssertEqual(app.cells.count, 0, "There should be 0 list rows initially.")
    }
    
    // Crea 5 issues y luego los elimina uno por uno, verificando el conteo.
    func testCreatingandDeletingIssues() {
        for tapCount in 1...5 {
            app.navigationBars.buttons["New issue"].tap()
            app.buttons["Issues"].tap()
            XCTAssertEqual(app.cells.count, tapCount, "There should be \(tapCount) rows in the list.")
        }
        
        for tapCount in (0...4).reversed() {
            app.cells.firstMatch.swipeLeft()
            app.buttons["Delete"].tap()
            XCTAssertEqual(app.cells.count, tapCount, "There should be \(tapCount) rows in the list.")
        }
    }

    // Edita el título de un issue y verifica que el cambio se vea reflejado.
    func testEditingIssueTitleUpdatesCorrectly() {
        XCTAssertEqual(app.cells.count, 0, "There should be no rows initially.")
        app.buttons["New issue"].tap()
        app.textFields["Enter the issue title here"].tap()
        app.textFields["Enter the issue title here"].clear()
        app.typeText("My New Issue")
        app.buttons["Issues"].tap()
        XCTAssertTrue(app.buttons["My New Issue"].exists, "A My New Issue cell should now exist.")
    }

    // Cambia la prioridad de un issue y verifica que se muestre el ícono correspondiente.
    func testEditingIssuePriorityShowsIcon() {
        app.buttons["New issue"].tap()
        app.buttons["Priority, Medium"].tap()
        app.buttons["High"].tap()
        app.buttons["Issues"].tap()
        let identifier = "New issue High Priority"
        XCTAssert(app.images[identifier].exists, "A high-priority issue needs an icon next to it.")
    }

    // Toca todos los premios y verifica que todos muestran una alerta de "Locked".
    func testAllAwardsShowLockedAlert() {
        app.buttons["Filters"].tap()
        app.buttons["Show awards"].tap()
        
        for award in app.scrollViews.buttons.allElementsBoundByIndex {
            award.tap()
            XCTAssertTrue(app.alerts["Locked"].exists, "There should be a Locked alert showing this award.")
            app.buttons["OK"].tap()
        }
    }
}
