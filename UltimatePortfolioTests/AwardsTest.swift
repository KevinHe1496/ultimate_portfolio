//
//  AwardsTest.swift
//  UltimatePortfolioTests
//
//  Created by Kevin Heredia on 11/4/25.
//
import CoreData
import XCTest
@testable import UltimatePortfolio

final class AwardsTest: BaseTestCase {

    let awards = Award.allAwards
    
    func testAwardIDMatchesName() {
        for award in awards {
            XCTAssertEqual(award.id, award.name, "Award ID should always match its name.")
        }
    }
    
    func testNewUserHasUnlickedNoAwards() {
        for award in awards {
            XCTAssertFalse(dataController.hasEarned(award: award), "New users should have no earned awards.")
        }
    }
    
    func testClosingIssuesUnlockAwards() {
        let values = [1, 10, 20, 50, 100, 250, 500, 1000]
        
        for (count, value) in values.enumerated() {
            var issues = [Issue]()
            
            for _ in 0..<value {
                let issue = Issue(context: managedObjectContext)
                issue.completed = true
                issues.append(issue)
            }
            
            let matches = awards.filter { award in
                award.criterion == "closed" && dataController.hasEarned(award: award)
            }
            
            XCTAssertEqual(matches.count, count + 1, "Completing \(value) issues should unlock \(count + 1) awards")
            dataController.deleteAll()
        }
    }
    
    func testCreatingIssuesUnlockAwards() {
        let values = [1, 10, 20, 50, 100, 250, 500, 1000]
        
        for (count, value) in values.enumerated() {
            var issues = [Issue]()
            
            for _ in 0..<value {
                let issue = Issue(context: managedObjectContext)
                issues.append(issue)
            }
            
            let matches = awards.filter { award in
                award.criterion == "issues" && dataController.hasEarned(award: award)
            }
            
            XCTAssertEqual(matches.count, count + 1, "Adding \(value) issues should unlock \(count + 1) awards")
            dataController.deleteAll()
        }
    }
}
