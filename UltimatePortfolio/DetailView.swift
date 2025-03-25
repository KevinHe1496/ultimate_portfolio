//
//  DetailView.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 21/3/25.
//

import SwiftUI

struct DetailView: View {
    @EnvironmentObject var dataController: DataController
    
    var body: some View {
        // mostrar si tiene  el usuario un issue seleccionado, o no
        VStack {
            if let issue = dataController.selectedIssue {
                IssueView(issue: issue)
            } else {
                NoIssueView()
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    DetailView()
}
