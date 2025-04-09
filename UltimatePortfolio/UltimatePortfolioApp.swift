//
//  UltimatePortfolioApp.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 19/3/25.
//

import SwiftUI

@main
struct UltimatePortfolioApp: App {
    @StateObject var dataController = DataController()
    @Environment(\.scenePhase) var scenePhase // obseva el cambio de escena de nuestra app
    
    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                SidebarView()
            } content: {
                ContentView()
            } detail: {
                DetailView()
            }
            .environment(\.managedObjectContext, dataController.container.viewContext)
            .environmentObject(dataController)
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if oldPhase != newPhase, newPhase == .background {
                    dataController.save() // Guardar cuando la app pasa a segundo plano
                }
            }
        }
    }
}
