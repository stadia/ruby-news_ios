//
//  ruby_newsUITests.swift
//  ruby-newsUITests
//
//  Created by JEFF.DEAN on 5/6/26.
//

import XCTest

final class ruby_newsUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testPrimaryTabsExistAndCanBeSelected() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        for title in ["뉴스", "피드", "내 정보"] {
            let tab = tabBar.buttons[title]
            XCTAssertTrue(tab.exists, "\(title) 탭이 표시되어야 합니다.")
            tab.tap()
            XCTAssertTrue(tab.isSelected, "\(title) 탭을 선택할 수 있어야 합니다.")
        }
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
