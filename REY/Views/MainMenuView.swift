import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var gameState: GameState
    @State private var showGame = false
    @State private var showMissions = false
    @State private var showJournal = false
    @State private var titleGlow = false
    @State private var starsOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "#0d1b2a"), Color(hex: "#112233"), Color(hex: "#0a2018")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Animated stars
            GeometryReader { geo in
                ForEach(0..<60, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.3...0.9)))
                        .frame(width: CGFloat.random(in: 1...2.5), height: CGFloat.random(in: 1...2.5))
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height * 0.7)
                        )
                }
            }
            .ignoresSafeArea()

            // Temple silhouette at bottom
            GeometryReader { geo in
                TempleSilhouette()
                    .frame(width: geo.size.width, height: geo.size.height * 0.45)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.78)
            }
            .ignoresSafeArea()

            // Content
            HStack(spacing: 0) {
                // Left: Title + stats
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("REY")
                            .font(.system(size: 80, weight: .black, design: .monospaced))
                            .foregroundColor(Color(hex: "#f5c842"))
                            .shadow(color: Color(hex: "#f5c842").opacity(titleGlow ? 0.8 : 0.2), radius: titleGlow ? 24 : 6)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.8).repeatForever()) {
                                    titleGlow.toggle()
                                }
                            }

                        Text("EL REINO DORADO")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(hex: "#a0956a"))
                            .tracking(5)
                    }

                    Spacer().frame(height: 32)

                    // Stats row
                    HStack(spacing: 20) {
                        StatPill(icon: "💰", value: "\(gameState.totalGold)")
                        StatPill(icon: "🏺", value: "\(gameState.artifactsCollected)")
                        StatPill(icon: "🔍", value: "\(gameState.collectedClues.count)/\(Clue.allClues.count)")
                    }

                    Spacer().frame(height: 48)

                    Text("© 2025 ANA KALUGINA")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.25))
                        .tracking(2)

                    Spacer()
                }
                .padding(.leading, 48)
                .frame(maxWidth: .infinity)

                // Right: Buttons
                VStack(spacing: 16) {
                    Spacer()

                    MenuButton(title: "▶  PLAY", color: Color(hex: "#f5c842")) {
                        showGame = true
                    }
                    MenuButton(title: "📅  MISSIONS", color: Color(hex: "#5bc0de")) {
                        showMissions = true
                    }
                    MenuButton(title: "🔍  JOURNAL", color: Color(hex: "#9b59b6")) {
                        showJournal = true
                    }

                    Spacer()
                }
                .padding(.trailing, 48)
                .frame(maxWidth: 280)
            }
        }
        .fullScreenCover(isPresented: $showGame) {
            GameView().environmentObject(gameState)
        }
        .sheet(isPresented: $showMissions) {
            DailyMissionsView().environmentObject(gameState)
        }
        .sheet(isPresented: $showJournal) {
            JournalView().environmentObject(gameState)
        }
    }
}

// MARK: - Sub-components

struct MenuButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.15)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.15)) { pressed = false }
                action()
            }
        }) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "#0d1b2a"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(color.opacity(0.4), lineWidth: 2)
                                .blur(radius: 4)
                        )
                )
                .scaleEffect(pressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

struct StatPill: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Text(icon).font(.system(size: 14))
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "#f5c842"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.07))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

struct TempleSilhouette: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Trees background
                ForEach(0..<14, id: \.self) { i in
                    let x = CGFloat(i) * (w / 13)
                    let treeH = CGFloat.random(in: h * 0.4...h * 0.85)
                    PixelTree(height: treeH, color: Color(hex: "#0a2515"))
                        .position(x: x, y: h - treeH * 0.45)
                }

                // Temple
                ZStack {
                    // Base block
                    Rectangle()
                        .fill(Color(hex: "#1a1208"))
                        .frame(width: w * 0.22, height: h * 0.55)
                        .position(x: w / 2, y: h * 0.73)

                    // Pyramid
                    TriangleShape()
                        .fill(Color(hex: "#1a1208"))
                        .frame(width: w * 0.28, height: h * 0.5)
                        .position(x: w / 2, y: h * 0.28)

                    // Gold top glow
                    Circle()
                        .fill(Color(hex: "#f5c842").opacity(0.4))
                        .frame(width: 30, height: 30)
                        .blur(radius: 8)
                        .position(x: w / 2, y: h * 0.04)
                    Circle()
                        .fill(Color(hex: "#f5c842"))
                        .frame(width: 10, height: 10)
                        .position(x: w / 2, y: h * 0.04)

                    // Door
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: w * 0.05, height: h * 0.2)
                        .position(x: w / 2, y: h * 0.92)
                }
            }
        }
    }
}

struct PixelTree: View {
    let height: CGFloat
    let color: Color

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(hex: "#2a1a0a"))
                .frame(width: height * 0.12, height: height * 0.4)
                .offset(y: height * 0.3)
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: height * 0.55, height: height * 0.5)
                .offset(y: -height * 0.05)
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: height * 0.4, height: height * 0.45)
                .offset(y: -height * 0.26)
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: height * 0.25, height: height * 0.35)
                .offset(y: -height * 0.43)
        }
    }
}

struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
