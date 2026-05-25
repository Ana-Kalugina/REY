import SwiftUI
import SpriteKit

struct GameView: View {
    @EnvironmentObject var gameState: GameState
    @Environment(\.dismiss) var dismiss
    @State private var showPause = false
    @State private var scene: GameScene?

    var body: some View {
        ZStack {
            if let scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea()
                    .statusBar(hidden: true)
            }

            // Pause button
            VStack {
                HStack {
                    Button {
                        showPause = true
                        scene?.isPaused = true
                    } label: {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(12)
                            .background(Color.black.opacity(0.35))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 20)
                    .padding(.top, 12)
                    Spacer()
                }
                Spacer()
            }

            if showPause {
                PauseOverlay(
                    onResume: {
                        showPause = false
                        scene?.isPaused = false
                    },
                    onQuit: {
                        dismiss()
                    }
                )
            }
        }
        .onAppear {
            gameState.resetLevelStats()
            let s = GameScene(size: UIScreen.main.bounds.size, characterType: gameState.selectedCharacter)
            s.scaleMode = .aspectFill
            s.onGoldCollected = { [weak gameState] amount in
                DispatchQueue.main.async { gameState?.addGold(amount) }
            }
            s.onArtifactCollected = { [weak gameState] in
                DispatchQueue.main.async { gameState?.collectArtifact() }
            }
            s.onClueFound = { [weak gameState] clue in
                DispatchQueue.main.async { gameState?.addClue(clue) }
            }
            s.onLevelComplete = { [weak gameState] time, noDamage in
                DispatchQueue.main.async { gameState?.levelCompleted(time: time, noDamage: noDamage) }
            }
            scene = s
        }
    }
}

struct PauseOverlay: View {
    let onResume: () -> Void
    let onQuit: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("⏸ PAUSED")
                    .font(.system(size: 26, weight: .black, design: .monospaced))
                    .foregroundColor(Color(hex: "#f5c842"))

                Button {
                    onResume()
                } label: {
                    Text("▶  RESUME")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "#0d1b2a"))
                        .frame(width: 220)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#f5c842"))
                        .cornerRadius(4)
                }

                Button {
                    onQuit()
                } label: {
                    Text("← QUIT")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#0d1b2a"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#f5c842").opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}
