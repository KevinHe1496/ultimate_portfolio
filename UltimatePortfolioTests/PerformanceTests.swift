//
//  PerformanceTests.swift
//  UltimatePortfolioTests
//
//  Created by Kevin Heredia on 16/4/25.
//

import XCTest
@testable import UltimatePortfolio

final class PerformanceTests: BaseTestCase {
    func testAwardCalculationPerformance() {
        for _ in 1...100 {
            dataController.createSampleData()
        }
        let awards = Array(repeating: Award.allAwards, count: 25).joined()
        XCTAssertEqual(awards.count, 500, "This checks the awards count is constant. Change this if you add awards.")
        measure {
            _ = awards.filter(dataController.hasEarned)
        }
    }
}
