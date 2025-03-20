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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(dataController)
        }
    }
}
