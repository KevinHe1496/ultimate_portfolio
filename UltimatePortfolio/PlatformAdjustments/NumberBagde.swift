//
//  NumberBagde.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 17/6/25.
//

import SwiftUI

extension View {
    func numberBadge(_ number: Int) -> some View {
        #if os(watchOS)
        self
        #else
        self.badge(number)
        #endif
    }
}
