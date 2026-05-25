import SwiftUI
import Combine

class GameState: ObservableObject {
    @Published var score: Int = 0
    @Published var totalGold: Int = 0
    @Published var artifactsCollected: Int = 0
    @Published var lives: Int = 3
    @Published var collectedClues: [Clue] = []
    @Published var dailyMissions: [Mission] = []
    @Published var currentLevelGold: Int = 0

    init() {
        generateDailyMissions()
    }

    func addClue(_ clue: Clue) {
        guard !collectedClues.contains(where: { $0.id == clue.id }) else { return }
        collectedClues.append(clue)
        propagate(.clueFound)
    }

    func collectArtifact() {
        artifactsCollected += 1
        score += 500
        propagate(.artifactCollected)
    }

    func addGold(_ amount: Int) {
        totalGold += amount
        currentLevelGold += amount
        score += amount * 10
        propagate(.goldCollected(amount))
    }

    func levelCompleted(time: Double, noDamage: Bool) {
        score += noDamage ? 1000 : 300
        propagate(.levelCompleted(time: time, noDamage: noDamage))
        currentLevelGold = 0
    }

    func resetLevelStats() {
        currentLevelGold = 0
        lives = 3
    }

    func generateDailyMissions() {
        let seed = (Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1)
        let pool: [Mission] = [
            Mission(id: "gold_5",     title: "Gold Hunter",    description: "Collect 5 coins",          icon: "💰", target: 5,  type: .collectGold),
            Mission(id: "gold_10",    title: "Rey's Treasure", description: "Collect 10 coins",         icon: "💎", target: 10, type: .collectGold),
            Mission(id: "clue_1",     title: "Detective Rey",  description: "Find 1 clue",              icon: "🔍", target: 1,  type: .findClue),
            Mission(id: "clue_2",     title: "Tracker",        description: "Find 2 clues",             icon: "🧩", target: 2,  type: .findClue),
            Mission(id: "artifact_1", title: "Explorer",       description: "Collect 1 artifact",       icon: "🏺", target: 1,  type: .collectArtifact),
            Mission(id: "no_damage",  title: "Untouchable",    description: "Complete level unharmed",  icon: "🛡️", target: 1,  type: .surviveLevel),
            Mission(id: "speed_60",   title: "Lightning",      description: "Finish level in 60 sec",   icon: "⚡", target: 60, type: .speedRun),
        ]
        let i0 = seed % pool.count
        let i1 = (seed + 2) % pool.count
        let i2 = (seed + 4) % pool.count
        dailyMissions = [pool[i0], pool[i1], pool[i2]]
    }

    private func propagate(_ event: MissionEvent) {
        for i in dailyMissions.indices {
            dailyMissions[i].update(for: event)
        }
    }
}
