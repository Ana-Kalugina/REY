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
            title: "Каменная карта",
            description: "Фрагмент карты, вырезанный в скале. На ней изображены три горы и извилистая река, ведущая к солнцу.",
            symbol: "🗺️",
            levelFound: 1
        ),
        Clue(
            id: "golden_mask",
            title: "Золотая маска",
            description: "Маска жреца солнца. Надпись на обороте: «Иди туда, куда падает первый луч рассвета».",
            symbol: "🎭",
            levelFound: 1
        ),
        Clue(
            id: "ancient_coin",
            title: "Монета Эль-Рея",
            description: "Монета с профилем короля в перьевой короне. На обороте — звезда с восемью лучами.",
            symbol: "🪙",
            levelFound: 2
        ),
        Clue(
            id: "jungle_totem",
            title: "Тотем джунглей",
            description: "Деревянный тотем с символами птиц. Стрела в основании указывает строго на запад.",
            symbol: "🗿",
            levelFound: 2
        ),
        Clue(
            id: "temple_inscription",
            title: "Надпись на храме",
            description: "Древние письмена на воротах: «Золотой город откроется тому, кто докажет своё достоинство».",
            symbol: "📜",
            levelFound: 3
        ),
    ]
}
