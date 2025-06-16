//
//  InlineNavigationBar.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 16/6/25.
//

import SwiftUI

extension View {
    func inlineNavigationBar() -> some View {
        #if os(macOS)
        self
        #else
        self.navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
