//
//  TagTests.swift
//  UltimatePortfolioTests
//
//  Created by Kevin Heredia on 11/4/25.
//
import CoreData
import XCTest
@testable import UltimatePortfolio

final class TagTests: BaseTestCase {

    func testCreatingTagsAndIssues() {
        let count = 10
        let issueCount = count * count

        for _ in 0..<count {
            let tag = Tag(context: managedObjectContext)

            for _ in 0..<count {
                let issue = Issue(context: managedObjectContext)
                tag.addToIssues(issue)
            }
        }

        XCTAssertEqual(dataController.count(for: Tag.fetchRequest()), count, "Expected \(count) tags.")
        XCTAssertEqual(dataController.count(for: Issue.fetchRequest()), issueCount, "Expected \(issueCount) issues.")
    }

    func testDeletingTagNoesNotDeleteIssues() throws {
        dataController.createSampleData()
        
        let request = NSFetchRequest<Tag>(entityName: "Tag")
        let tags = try managedObjectContext.fetch(request)
        
        dataController.delete(tags[0])
        
        XCTAssertEqual(dataController.count(for: Tag.fetchRequest()), 4, "There should be 4 tags after  deleting 1 from our sample data.")
        XCTAssertEqual(dataController.count(for: Issue.fetchRequest()), 50, "There should be 50 issues after  deleting a tag from our sample data.")
    }
}
