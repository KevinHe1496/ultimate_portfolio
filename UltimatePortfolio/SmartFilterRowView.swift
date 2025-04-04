//
//  SmartFilterRowView.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 4/4/25.
//

import SwiftUI

struct SmartFilterRowView: View {
    var filter: Filter
    
    var body: some View {
        NavigationLink(value: filter) {
            Label(LocalizedStringKey(filter.name), systemImage: filter.icon)
        }
    }
}

#Preview {
    SmartFilterRowView(filter: .all)
}
