//
//  PortfolioWidgetBundle.swift
//  PortfolioWidget
//
//  Created by Kevin Heredia on 5/6/25.
//

import WidgetKit
import SwiftUI

@main
struct PortfolioWidgetBundle: WidgetBundle {
    var body: some Widget {
        SimplePortfolioWidget()
        ComplexPortfolioWidget()
    }
}
