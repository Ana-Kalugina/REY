import Foundation

enum MissionType: String, Codable {
    case collectGold
    case findClue
    case collectArtifact
    case surviveLevel
    case speedRun
}

enum MissionEvent {
    case goldCollected(Int)
    case artifactCollected
    case clueFound
    case levelCompleted(time: Double, noDamage: Bool)
}

struct Mission: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let target: Int
    let type: MissionType
    var progress: Int = 0
    var isCompleted: Bool = false

    var progressFraction: Double {
        guard target > 0 else { return 0 }
        return min(Double(progress) / Double(target), 1.0)
    }

    var rewardGold: Int { target * 15 }

    mutating func update(for event: MissionEvent) {
        guard !isCompleted else { return }
        switch (type, event) {
        case (.collectGold, .goldCollected(let n)):    progress += n
        case (.findClue, .clueFound):                  progress += 1
        case (.collectArtifact, .artifactCollected):   progress += 1
        case (.surviveLevel, .levelCompleted(_, let noDamage)) where noDamage:
            progress = target
        case (.speedRun, .levelCompleted(let t, _)) where t <= Double(target):
            progress = target
        default: break
        }
        if progress >= target { isCompleted = true; progress = target }
    }
}
