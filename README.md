# REY — El Reino Dorado

> A GBC-inspired 2D platformer with detective mechanics for iOS

**REY** is a side-scrolling adventure game where you play as Rey — a young archaeologist uncovering the mystery of the lost golden city *El Reino Dorado*. Each level combines classic platformer gameplay with detective investigation: find hidden clues, collect ancient artifacts, and piece together the secret of the golden kingdom.

---

## Features

- **Platformer gameplay** — run, jump, avoid jungle guardians
- **Detective system** — find clues scattered across levels, add them to your journal
- **Daily Missions** — 3 rotating challenges every day (collect gold, find clues, speedrun, survive without damage)
- **Journal** — collect all 5 clues to reveal the full story of El Dorado
- **GBC-inspired pixel art** — drawn programmatically with SpriteKit
- **Atmospheric design** — parallax jungle backgrounds, torches, moonlit sky

---

## Tech Stack

| Layer | Tech |
|---|---|
| Game engine | SpriteKit |
| UI | SwiftUI |
| Target | iOS 17+ |
| Language | Swift 5.10 |

---

## Project Structure

```
REY/
├── App/           — App entry point
├── Models/        — GameState, Mission, Clue
├── Views/         — SwiftUI: MainMenu, DailyMissions, Journal, GameView
├── Game/          — SpriteKit: GameScene, PlayerNode, EnemyNode,
│                    CollectibleNode, ClueNode, HUDNode, ControlsNode
└── Extensions/    — UIColor/Color hex helpers
```

---

## Getting Started

1. Clone the repo
2. Open `REY.xcodeproj` in Xcode 16+
3. Select an iPhone simulator (landscape orientation)
4. Build & Run

> Requires Xcode 16+ and iOS 17 SDK.

---

## Roadmap

- [ ] Chapter 2 — deeper jungle, new enemies
- [ ] Boss fight — temple guardian
- [ ] Haptic feedback on jumps and collectibles
- [ ] Game Center leaderboard
- [ ] iCloud sync for progress
- [ ] App Store release

---

*© 2025 Ana Kalugina*
