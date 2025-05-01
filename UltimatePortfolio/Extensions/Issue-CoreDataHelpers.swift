//
//  Issue-CoreDataHelpers.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 24/3/25.
//

import Foundation

// como en coredata todos son opcionales aqui manejamos eso para que no sea un opcional.
extension Issue {
    var issueTitle: String {
        get { title ?? "" }
        set { title = newValue }
    }
    
    var issueContent: String {
        get { content ?? "" }
        set { content = newValue }
    }
    
    var issueCreationDate: Date {
        creationDate ?? .now
    }
    
    var issueModificationDate: Date {
        modificationDate ?? .now
    }
    
    /// ordena todas las etiquetas
    var issueTags: [Tag] {
        let result = tags?.allObjects as? [Tag] ?? []
        return result.sorted()
    }
    
    // damos solo los problemas con sus nombres
    var issueTagsList: String {
        let noTags = NSLocalizedString("No tags", comment: "The user has no created any tags yet.")
        guard let tags else { return noTags }
        
        if tags.count == 0 {
            return noTags
        } else {
            return issueTags.map(\.tagName).formatted()
        }
    }
    
    // convertimos completed a un string
    // te dice si esta completado o no
    var issueStatus: String {
        if completed {
            return NSLocalizedString("Closed", comment: "This issue has been resolved by the user.")
        } else {
            return NSLocalizedString("Open", comment: "This issue is currently unresolved.")
        }
    }
    
    static var example: Issue {
        let controller = DataController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        let issue = Issue(context: viewContext)
        issue.title = "example Issue"
        issue.content = "This is an example issue."
        issue.priority = 2
        issue.creationDate = .now
        return issue
    }
}

extension Issue: Comparable {
    
    /// Se ordena los issue por titulo, pero si tiene el mismo titulo ordena por fecha de creacion 
    public static func <(lhs: Issue, rhs: Issue) -> Bool {
        let left = lhs.issueTitle.localizedLowercase
        let right = rhs.issueTitle.localizedLowercase
        
        if left == right {
            return lhs.issueCreationDate < rhs.issueCreationDate
        } else {
            return left < right
        }
    }
}
