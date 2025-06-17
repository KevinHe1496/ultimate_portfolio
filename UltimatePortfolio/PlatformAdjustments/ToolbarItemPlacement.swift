//
//  ToolbarItemPlacement.swift
//  UltimatePortfolio
//
//  Created by Kevin Heredia on 17/6/25.
//

import SwiftUI

extension ToolbarItemPlacement {
#if os(watchOS)
    static let automaticOrLeading = ToolbarItemPlacement.topBarLeading
    static let automaticOrTrailing = ToolbarItemPlacement.topBarTrailing
#else
    static let automaticOrLeading = ToolbarItemPlacement.automatic
    static let automaticOrTrailing = ToolbarItemPlacement.automatic
#endif
}
