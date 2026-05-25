import SwiftUI

struct JournalView: View {
    @EnvironmentObject var gameState: GameState
    @Environment(\.dismiss) var dismiss
    @State private var selectedClue: Clue?

    var body: some View {
        ZStack {
            Color(hex: "#0d1b2a").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("REY'S JOURNAL")
                            .font(.system(size: 22, weight: .black, design: .monospaced))
                            .foregroundColor(Color(hex: "#9b59b6"))
                        Text("\(gameState.collectedClues.count) of \(Clue.allClues.count) clues found")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.45))
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)

                Divider().background(Color.white.opacity(0.1))

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                        ForEach(Clue.allClues) { clue in
                            let found = gameState.collectedClues.contains(where: { $0.id == clue.id })
                            ClueCard(clue: clue, found: found)
                                .onTapGesture {
                                    if found { selectedClue = clue }
                                }
                        }
                    }
                    .padding(24)
                }
            }

            // Detail overlay
            if let clue = selectedClue {
                ClueDetailOverlay(clue: clue) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedClue = nil
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.spring(response: 0.3), value: selectedClue?.id)
    }
}

struct ClueCard: View {
    let clue: Clue
    let found: Bool

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(found ? Color(hex: "#9b59b6").opacity(0.15) : Color.white.opacity(0.04))
                    .frame(height: 64)
                if found {
                    Text(clue.symbol)
                        .font(.system(size: 34))
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.2))
                }
            }

            Text(found ? clue.title : "???")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(found ? .white : .white.opacity(0.3))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text("Level \(clue.levelFound)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(found ? Color(hex: "#9b59b6") : .white.opacity(0.2))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            found ? Color(hex: "#9b59b6").opacity(0.35) : Color.white.opacity(0.06),
                            lineWidth: 1
                        )
                )
        )
    }
}

struct ClueDetailOverlay: View {
    let clue: Clue
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 20) {
                Text(clue.symbol)
                    .font(.system(size: 60))

                Text(clue.title)
                    .font(.system(size: 20, weight: .black, design: .monospaced))
                    .foregroundColor(Color(hex: "#f5c842"))

                Text(clue.description)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                HStack {
                    Image(systemName: "map.fill")
                        .foregroundColor(Color(hex: "#9b59b6"))
                    Text("Found in level \(clue.levelFound)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color(hex: "#9b59b6"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(hex: "#9b59b6").opacity(0.12))
                .clipShape(Capsule())

                Button("Close") { onDismiss() }
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "#0d1b2a"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "#9b59b6").opacity(0.4), lineWidth: 1.5)
                    )
            )
            .padding(32)
        }
    }
}
