//
//  SideBarViewToolbar.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 4/4/25.
//

import SwiftUI

struct SideBarViewToolbar: View {
    @EnvironmentObject var dataController: DataController
    @State private var showingAwards = false
    @State private var showingStore = false
    
    var body: some View {
        Button(action: tryNewTag) {
            Label("Add tag", systemImage: "plus")
        }
        .sheet(isPresented: $showingStore, content: StoreView.init)
        
        Button {
            showingAwards.toggle()
        } label: {
            Label("Show awards", systemImage: "rosette")
        }
        .sheet(isPresented: $showingAwards, content: AwardsView.init)
        
#if DEBUG
        Button {
            dataController.deleteAll()
            dataController.createSampleData()
        } label: {
            Label("ADD SAMPLES", systemImage: "flame")
        }
#endif
    }
    func tryNewTag() {
        if dataController.newTag() == false {
            showingStore = true
        }
    }
}

#Preview {
    SideBarViewToolbar()
}
