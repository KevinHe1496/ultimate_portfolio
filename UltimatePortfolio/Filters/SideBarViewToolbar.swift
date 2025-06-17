//
//  SideBarViewToolbar.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 4/4/25.
//

import SwiftUI

struct SideBarViewToolbar: ToolbarContent {
    @EnvironmentObject var dataController: DataController
    @State private var showingAwards = false
    @State private var showingStore = false
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .automaticOrTrailing) {
            Button(action: tryNewTag) {
                Label("Add tag", systemImage: "plus")
            }
            .sheet(isPresented: $showingStore, content: StoreView.init)
            .help("Add tag")
        }
        ToolbarItem(placement: .automaticOrLeading) {
            Button {
                showingAwards.toggle()
            } label: {
                Label("Show awards", systemImage: "rosette")
            }
            .sheet(isPresented: $showingAwards, content: AwardsView.init)
            .help("Show awards")
        }
#if DEBUG
        ToolbarItem(placement: .automatic) {
            Button {
                dataController.deleteAll()
                dataController.createSampleData()
            } label: {
                Label("ADD SAMPLES", systemImage: "flame")
            }
        }
#endif
    }
    func tryNewTag() {
        if dataController.newTag() == false {
            showingStore = true
        }
    }
}
