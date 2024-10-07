//
//  WordLeZApp.swift
//  WordLeZ
//
//  Created by 周源坤 on 10/6/24.
//

import SwiftUI

@main
struct WordLeZApp: App {
    @State private var gameLogic = GameLogic()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(gameLogic)
        }
    }
}
