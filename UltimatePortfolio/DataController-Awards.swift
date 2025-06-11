//
//  DataController-Awards.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 5/6/25.
//

import Foundation

extension DataController {
    /// Premios que ha ganamos segun los issues, closed, tags
    func hasEarned(award: Award) -> Bool {
        switch award.criterion {
        case "issues":
            // return true if they added a certain number of issues
            let fetchRequest = Issue.fetchRequest()
            let awadCount = count(for: fetchRequest)
            return awadCount >= award.value
            
        case "closed":
            // returns true if they closed a certain number of issues
            let fetchRequest = Issue.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "completed = true")
            let awardCount = count(for: fetchRequest)
            return awardCount >= award.value
            
        case "tags":
            // return true if they created a certain number of tags
            let fetchRequest = Tag.fetchRequest()
            let awardCount = count(for: fetchRequest)
            return awardCount >= award.value
            
        case "unlock":
            return fullVersionUnlocked
            
        default:
            // an unknown award criterion; this should never be allowed
            // fatalError("Unknown award criterion: \(award.criterion)")
            return false
        }
    }
}
