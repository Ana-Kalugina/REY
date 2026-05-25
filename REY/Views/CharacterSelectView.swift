import SwiftUI

struct CharacterSelectView: View {
    @EnvironmentObject var gameState: GameState
    @State private var showGame = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#080414"), Color(hex: "#1a0838"),
                    Color(hex: "#38122a"), Color(hex: "#6a3005"),
                ],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            // Stars
            GeometryReader { geo in
                ForEach(0..<80, id: \.self) { i in
                    let seed = Double(i) * 1.618
                    Circle()
                        .fill(Color(hex: "#fff0d0").opacity(Double.random(in: 0.2...0.85)))
                        .frame(width: CGFloat.random(in: 1...2.5))
                        .position(
                            x: geo.size.width  * CGFloat(seed.truncatingRemainder(dividingBy: 97)  / 97),
                            y: geo.size.height * CGFloat(seed.truncatingRemainder(dividingBy: 113) / 113) * 0.8
                        )
                }
            }.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 4) {
                    Text("REY")
                        .font(.custom("Courier-Bold", size: 52))
                        .foregroundColor(Color(hex: "#f5c842"))
                        .shadow(color: Color(hex: "#f5c842").opacity(0.6), radius: 20)
                    Text("CHOOSE YOUR HERO")
                        .font(.custom("Courier-Bold", size: 13))
                        .foregroundColor(.white.opacity(0.55))
                        .tracking(5)
                }
                Spacer().frame(height: 32)

                HStack(spacing: 40) {
                    HeroCard(name: "REY", subtitle: "Explorer King", isFemale: false) {
                        gameState.selectedCharacter = .male
                        showGame = true
                    }
                    HeroCard(name: "REINA", subtitle: "Explorer Queen", isFemale: true) {
                        gameState.selectedCharacter = .female
                        showGame = true
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .fullScreenCover(isPresented: $showGame) {
            GameView().environmentObject(gameState)
        }
    }
}

private struct HeroCard: View {
    let name: String
    let subtitle: String
    let isFemale: Bool
    let onPlay: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.12)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.18)) { pressed = false }
                onPlay()
            }
        }) {
            VStack(spacing: 14) {
                // Character + horse portrait
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "#120826"))
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "#f5c842").opacity(0.55), lineWidth: 1.5)
                    HeroPortrait(isFemale: isFemale)
                        .frame(width: 100, height: 90)
                }
                .frame(width: 150, height: 120)

                VStack(spacing: 3) {
                    Text(name)
                        .font(.custom("Courier-Bold", size: 20))
                        .foregroundColor(Color(hex: "#f5c842"))
                    Text(subtitle)
                        .font(.custom("Courier", size: 10))
                        .foregroundColor(.white.opacity(0.45))
                }

                Text("▶  PLAY")
                    .font(.custom("Courier-Bold", size: 13))
                    .foregroundColor(Color(hex: "#0d1220"))
                    .padding(.horizontal, 28).padding(.vertical, 10)
                    .background(Color(hex: "#f5c842"))
                    .cornerRadius(6)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "#100c28").opacity(0.94))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "#f5c842").opacity(0.18), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(pressed ? 0.94 : 1.0)
    }
}

private struct HeroPortrait: View {
    let isFemale: Bool
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            // Horse body
            let horseBody = Path(CGRect(x: w*0.05, y: h*0.45, width: w*0.78, height: h*0.28).insetBy(dx: -2, dy: 0))
            ctx.fill(horseBody, with: .color(Color(hex: "#7a3a10")))

            // Horse legs
            for lx in [w*0.18, w*0.28, w*0.54, w*0.64] {
                ctx.fill(Path(CGRect(x: lx, y: h*0.71, width: w*0.09, height: h*0.26)),
                         with: .color(Color(hex: "#5a2808")))
            }

            // Horse head+neck
            var neck = Path(); neck.move(to: CGPoint(x: w*0.7, y: h*0.52))
            neck.addLine(to: CGPoint(x: w*0.82, y: h*0.32))
            neck.addLine(to: CGPoint(x: w*0.92, y: h*0.32))
            neck.addLine(to: CGPoint(x: w*0.85, y: h*0.54)); neck.closeSubpath()
            ctx.fill(neck, with: .color(Color(hex: "#7a3a10")))
            ctx.fill(Path(CGRect(x: w*0.82, y: h*0.22, width: w*0.14, height: h*0.22).insetBy(dx: -1, dy: 0)),
                     with: .color(Color(hex: "#7a3a10")))

            // Saddle
            ctx.fill(Path(CGRect(x: w*0.28, y: h*0.40, width: w*0.38, height: h*0.12)),
                     with: .color(Color(hex: "#6a1010")))

            // Rider torso
            let jColor = isFemale ? Color(hex: "#2a6a5a") : Color(hex: "#a07030")
            ctx.fill(Path(CGRect(x: w*0.30, y: h*0.15, width: w*0.32, height: h*0.30)),
                     with: .color(jColor))

            // Rider head (skin)
            ctx.fill(Path(ellipseIn: CGRect(x: w*0.33, y: h*0.04, width: w*0.24, height: h*0.22)),
                     with: .color(Color(hex: "#d4906a")))

            // Hat brim
            ctx.fill(Path(CGRect(x: w*0.26, y: h*0.07, width: w*0.38, height: h*0.07)),
                     with: .color(isFemale ? Color(hex: "#6a4020") : Color(hex: "#7a4a10")))
            // Hat crown
            ctx.fill(Path(CGRect(x: w*0.30, y: h*0.00, width: w*0.28, height: h*0.12)),
                     with: .color(isFemale ? Color(hex: "#6a4020") : Color(hex: "#7a4a10")))
            // Hat band
            ctx.fill(Path(CGRect(x: w*0.30, y: h*0.08, width: w*0.28, height: h*0.03)),
                     with: .color(Color(hex: "#f5c842")))
        }
    }
}
