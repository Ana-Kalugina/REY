import Foundation

struct Clue: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let symbol: String
    let levelFound: Int

    static let allClues: [Clue] = [
        Clue(
            id: "stone_map",
            title: "Stone Map",
            description: "A map fragment carved into rock. It shows three mountains and a winding river leading toward the sun.",
            symbol: "🗺️",
            levelFound: 1
        ),
        Clue(
            id: "golden_mask",
            title: "Golden Mask",
            description: "A sun priest's mask. The inscription on the back reads: 'Follow where the first ray of dawn falls'.",
            symbol: "🎭",
            levelFound: 1
        ),
        Clue(
            id: "ancient_coin",
            title: "El Rey Coin",
            description: "A coin bearing the king's profile wearing a feathered crown. The reverse shows an eight-pointed star.",
            symbol: "🪙",
            levelFound: 2
        ),
        Clue(
            id: "jungle_totem",
            title: "Jungle Totem",
            description: "A wooden totem carved with bird symbols. The arrow at its base points due west.",
            symbol: "🗿",
            levelFound: 2
        ),
        Clue(
            id: "temple_inscription",
            title: "Temple Inscription",
            description: "Ancient writing on the gate: 'The golden city shall reveal itself to those who prove their worth'.",
            symbol: "📜",
            levelFound: 3
        ),
    ]
}
