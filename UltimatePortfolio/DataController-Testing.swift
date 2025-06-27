//
//  DataController-Testing.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 27/6/25.
//

import SwiftUI

extension DataController {
    func checkForTestEnvironment() {
#if DEBUG
        if CommandLine.arguments.contains("enable-testing") {
            self.deleteAll()
#if os(iOS)
            UIView.setAnimationsEnabled(false)
#endif
        }
#endif
    }
}
