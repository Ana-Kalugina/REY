import SwiftUI

struct DailyMissionsView: View {
    @EnvironmentObject var gameState: GameState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color(hex: "#0d1b2a").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DAILY MISSIONS")
                            .font(.system(size: 22, weight: .black, design: .monospaced))
                            .foregroundColor(Color(hex: "#f5c842"))
                        Text(Date(), style: .date)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(Color(hex: "#a0956a"))
                    }
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
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
                    VStack(spacing: 16) {
                        ForEach(gameState.dailyMissions) { mission in
                            MissionCard(mission: mission)
                        }

                        // Reward hint
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(Color(hex: "#5bc0de"))
                            Text("Complete all missions — earn +150 bonus gold")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color(hex: "#5bc0de").opacity(0.8))
                        }
                        .padding()
                        .background(Color(hex: "#5bc0de").opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(24)
                }
            }
        }
    }
}

struct MissionCard: View {
    let mission: Mission

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Text(mission.icon)
                .font(.system(size: 30))
                .frame(width: 52, height: 52)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(mission.title)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(mission.isCompleted ? Color(hex: "#4caf50") : .white)
                    Spacer()
                    Text("+\(mission.rewardGold) 💰")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color(hex: "#f5c842"))
                }

                Text(mission.description)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.55))

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 5)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(mission.isCompleted ? Color(hex: "#4caf50") : Color(hex: "#f5c842"))
                            .frame(width: geo.size.width * mission.progressFraction, height: 5)
                            .animation(.spring(response: 0.5), value: mission.progressFraction)
                    }
                }
                .frame(height: 5)

                Text("\(mission.progress)/\(mission.target)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            mission.isCompleted ? Color(hex: "#4caf50").opacity(0.4) : Color.white.opacity(0.08),
                            lineWidth: 1
                        )
                )
        )
        .overlay(
            mission.isCompleted ?
            HStack {
                Spacer()
                VStack {
                    Text("✓")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(Color(hex: "#4caf50"))
                        .padding(8)
                    Spacer()
                }
            } : nil
        )
    }
}
