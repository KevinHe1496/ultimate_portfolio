//
//  UserFilterRowView.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 4/4/25.
//

import SwiftUI

struct UserFilterRowView: View {
    var filter: Filter
    var rename: (Filter) -> Void
    var delete: (Filter) -> Void
    
    
    var body: some View {
        NavigationLink(value: filter) {
            Label(filter.name, systemImage: filter.icon)
                .badge(filter.activeIssuesCount)
                .contextMenu {
                    Button {
                        rename(filter)
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        delete(filter)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .accessibilityElement()
                .accessibilityLabel(filter.name)
                .accessibilityHint("\(filter.activeIssuesCount) issues")
        }
    }
}

#Preview {
    UserFilterRowView(filter: .all, rename: { _ in }, delete: { _ in })
}
