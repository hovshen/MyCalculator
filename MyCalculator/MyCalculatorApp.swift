//
//  MyCalculatorApp.swift
//  MyCalculator
//
//  Created by Ho Shen Jui on 2025/10/23.
//

import SwiftUI

@main
struct MyCalculatorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: 720, height: 900)
        }
#if os(macOS)
        .defaultSize(width: 720, height: 900)
        .windowResizability(.contentSize)
#endif
    }
}
