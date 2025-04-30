//
//  IssueRow.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 24/3/25.
//

import SwiftUI

struct IssueRow: View {
    @EnvironmentObject var dataController: DataController
    @StateObject var viewModel: ViewModel
    
    var body: some View {
        NavigationLink(value: viewModel.issue) {
            HStack {
                Image(systemName: "exclamationmark.circle")
                    .imageScale(.large)
                // si tiene alta prioridad la opity sera 1 y si no sera 0
                    .opacity(viewModel.iconOpacity)
                    .accessibilityIdentifier(viewModel.iconIdenfifier)
                VStack(alignment: .leading) {
                    Text(viewModel.issueTitle)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(viewModel.issueTagsList)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    // muestra la fecha de creacion
                    Text(viewModel.creationDate)
                        .accessibilityLabel(viewModel.accessibilityCreationDate)
                        .font(.subheadline)
                    
                    if viewModel.completed {
                        Text("CLOSED")
                            .font(.body.smallCaps())
                    }
                }
                .foregroundStyle(.secondary)
            }
        }
        .accessibilityHint(viewModel.accessibilityHint)
        .accessibilityIdentifier(viewModel.issueTitle)
    }
    
    init(issue: Issue) {
        let viewModel = ViewModel(issue: issue)
        _viewModel = StateObject(wrappedValue: viewModel)
    }
}

#Preview {
    IssueRow(issue: .example)
}
