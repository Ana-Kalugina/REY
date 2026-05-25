import SwiftUI

@main
struct REYApp: App {
    @StateObject private var gameState = GameState()

    var body: some Scene {
        WindowGroup {
            MainMenuView()
                .environmentObject(gameState)
                .preferredColorScheme(.dark)
        }
    }
}
