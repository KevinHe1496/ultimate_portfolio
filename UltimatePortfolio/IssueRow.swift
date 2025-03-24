//
//  IssueRow.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 24/3/25.
//

import SwiftUI

struct IssueRow: View {
    @EnvironmentObject var dataController: DataController
    @ObservedObject var issue: Issue
    
    var body: some View {
        NavigationLink(value: issue) {
            HStack {
                Image(systemName: "exclamationmark.circle")
                    .imageScale(.large)
                // si tiene alta prioridad la opity sera 1 y si no sera 0
                    .opacity(issue.priority == 2 ? 1 : 0)
                
                VStack(alignment: .leading) {
                    Text(issue.issueTitle)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text("No tags")
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    // muestra la fecha de creacion
                    Text(issue.issueCreationDate.formatted(date: .numeric, time: .omitted))
                        .font(.subheadline)
                    
                    if issue.completed {
                        Text("CLOSED")
                            .font(.body.smallCaps())
                    }
                }
                .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    IssueRow(issue: .example)
}
