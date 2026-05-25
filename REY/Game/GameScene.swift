import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: - Callbacks (set from GameView)
    var onGoldCollected:    ((Int) -> Void)?
    var onArtifactCollected: (() -> Void)?
    var onClueFound:        ((Clue) -> Void)?
    var onLevelComplete:    ((Double, Bool) -> Void)?

    // MARK: - Physics categories
    struct Cat {
        static let player:     UInt32 = 0x1 << 0
        static let ground:     UInt32 = 0x1 << 1
        static let collectible:UInt32 = 0x1 << 2
        static let enemy:      UInt32 = 0x1 << 3
        static let clue:       UInt32 = 0x1 << 4
        static let levelEnd:   UInt32 = 0x1 << 5
    }

    // MARK: - State
    private var player: PlayerNode!
    private var cam: SKCameraNode!
    private var hud: HUDNode!
    private var controls: ControlsNode!
    private var enemies: [EnemyNode] = []

    private var isMovingLeft  = false
    private var isMovingRight = false
    private var tookDamage    = false
    private var invincible    = false
    private var levelDone     = false
    private var goldCount     = 0
    private var levelStartTime: TimeInterval = 0

    private let worldWidth: CGFloat = 3200
    private let tileSize:   CGFloat = 40

    // MARK: - Setup

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(hex: "#0d1b2a")
        setupPhysics()
        buildBackground()
        buildLevel()
        setupPlayer()
        setupCamera()
        setupHUD()
        setupControls()
        levelStartTime = Date().timeIntervalSince1970
    }

    // MARK: Physics world
    private func setupPhysics() {
        physicsWorld.gravity    = CGVector(dx: 0, dy: -12)
        physicsWorld.contactDelegate = self
        physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: 0, y: -100, width: worldWidth, height: size.height + 200))
    }

    // MARK: Background
    private func buildBackground() {
        // Sky — gradient via multiple horizontal strips
        let skyColors: [UIColor] = [
            UIColor(hex: "#0d1b2a"), UIColor(hex: "#0f2235"),
            UIColor(hex: "#122840"), UIColor(hex: "#0a2018"),
        ]
        for (i, color) in skyColors.enumerated() {
            let strip = SKSpriteNode(color: color, size: CGSize(width: worldWidth, height: size.height / CGFloat(skyColors.count) + 2))
            strip.anchorPoint = CGPoint(x: 0, y: 0)
            strip.position = CGPoint(x: 0, y: CGFloat(i) * (size.height / CGFloat(skyColors.count)))
            strip.zPosition = -20
            addChild(strip)
        }

        // Stars
        for _ in 0..<120 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...2))
            star.fillColor = .white
            star.strokeColor = .clear
            star.position = CGPoint(
                x: CGFloat.random(in: 0...worldWidth),
                y: CGFloat.random(in: size.height * 0.45...size.height * 1.0)
            )
            star.alpha = CGFloat.random(in: 0.2...0.9)
            star.zPosition = -19
            addChild(star)
        }

        // Moon
        let moonGlow = SKShapeNode(circleOfRadius: 40)
        moonGlow.fillColor = UIColor(hex: "#f5e6a0").withAlphaComponent(0.15)
        moonGlow.strokeColor = .clear
        moonGlow.position = CGPoint(x: worldWidth - 300, y: size.height * 0.88)
        moonGlow.zPosition = -18
        addChild(moonGlow)

        let moon = SKShapeNode(circleOfRadius: 28)
        moon.fillColor = UIColor(hex: "#f5e6a0")
        moon.strokeColor = .clear
        moon.position = CGPoint(x: worldWidth - 300, y: size.height * 0.88)
        moon.zPosition = -17
        addChild(moon)

        // Far background trees (parallax layer 1)
        buildParallaxTrees(count: 28, yBase: tileSize * 5 + 10, heightRange: 50...100, color: UIColor(hex: "#0a2515"), z: -10)
        // Mid trees (parallax layer 2)
        buildParallaxTrees(count: 20, yBase: tileSize * 5 + 5, heightRange: 70...130, color: UIColor(hex: "#0d3318"), z: -8)
    }

    private func buildParallaxTrees(count: Int, yBase: CGFloat, heightRange: ClosedRange<CGFloat>, color: UIColor, z: CGFloat) {
        let spacing = worldWidth / CGFloat(count)
        for i in 0..<count {
            let h = CGFloat.random(in: heightRange)
            let node = makePixelTree(height: h, color: color)
            node.position = CGPoint(x: CGFloat(i) * spacing + CGFloat.random(in: -15...15), y: yBase)
            node.zPosition = z
            addChild(node)
        }
    }

    // MARK: Level geometry
    private func buildLevel() {
        let ts = tileSize

        // Ground definition: array of column heights (in tiles)
        // 0 = pit, otherwise = stack that high
        let cols = Int(worldWidth / ts)
        var heights = [Int](repeating: 4, count: cols)

        // Pit gaps
        for gapStart in [18, 35, 55, 68] {
            for i in gapStart..<(gapStart + 3) { if i < cols { heights[i] = 0 } }
        }
        // Small terrain variation
        for i in stride(from: 0, to: cols, by: 7) {
            if heights[i] > 0 { heights[i] = 5 }
        }

        for (x, h) in heights.enumerated() {
            guard h > 0 else { continue }
            for y in 0..<h {
                let tile = makeTile(isTop: y == h - 1)
                tile.position = CGPoint(x: CGFloat(x) * ts + ts/2, y: CGFloat(y) * ts + ts/2)
                addChild(tile)
            }
        }

        // Floating platforms: (x tile, y tile, width in tiles)
        let platforms: [(Int, Int, Int)] = [
            (6, 7, 4), (14, 9, 3), (21, 7, 5), (29, 10, 4),
            (37, 8, 4), (44, 11, 5), (51, 9, 4), (59, 8, 3),
            (64, 12, 4), (70, 9, 3), (74, 7, 4)
        ]
        for (px, py, pw) in platforms {
            for i in 0..<pw {
                let tile = makeTile(isTop: true)
                tile.position = CGPoint(x: CGFloat(px + i) * ts + ts/2, y: CGFloat(py) * ts + ts/2)
                addChild(tile)
            }
        }

        // Foreground decoration plants & rocks
        placeDecoration()

        // Collectibles
        placeCollectibles(heights: heights)

        // Enemies
        placeEnemies()

        // Clues
        placeClues()

        // Level end: golden temple
        buildTemple(x: worldWidth - 140)
    }

    private func makeTile(isTop: Bool) -> SKSpriteNode {
        let ts = tileSize
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: ts, height: ts))
        let img = renderer.image { ctx in
            let c = ctx.cgContext
            if isTop {
                c.setFillColor(UIColor(hex: "#2d7a2d").cgColor)
                c.fill(CGRect(x: 0, y: ts - 9, width: ts, height: 9))
                c.setFillColor(UIColor(hex: "#8b4513").cgColor)
                c.fill(CGRect(x: 0, y: 0, width: ts, height: ts - 9))
                // grass detail
                c.setFillColor(UIColor(hex: "#3d9a3d").cgColor)
                for xi in stride(from: 2.0, through: ts - 6, by: 6.0) {
                    c.fill(CGRect(x: xi, y: ts - 13, width: 3, height: 5))
                }
            } else {
                c.setFillColor(UIColor(hex: "#6b3410").cgColor)
                c.fill(CGRect(x: 0, y: 0, width: ts, height: ts))
                // dirt detail
                c.setFillColor(UIColor(hex: "#7d4018").cgColor)
                c.fill(CGRect(x: 4, y: ts * 0.3, width: ts * 0.3, height: 4))
                c.fill(CGRect(x: ts * 0.55, y: ts * 0.65, width: ts * 0.3, height: 3))
            }
            // pixel border
            c.setStrokeColor(UIColor.black.withAlphaComponent(0.12).cgColor)
            c.setLineWidth(1)
            c.stroke(CGRect(x: 0.5, y: 0.5, width: ts - 1, height: ts - 1))
        }
        let node = SKSpriteNode(texture: SKTexture(image: img), size: CGSize(width: ts, height: ts))
        let body = SKPhysicsBody(rectangleOf: CGSize(width: ts, height: ts))
        body.isDynamic = false
        body.categoryBitMask    = Cat.ground
        body.collisionBitMask   = Cat.player | Cat.enemy
        body.contactTestBitMask = Cat.player
        body.friction = 0.3
        node.physicsBody = body
        node.zPosition = 0
        return node
    }

    private func placeDecoration() {
        let ts = tileSize
        let groundY = ts * 4 + ts / 2 + 16

        // Bushes (small green shapes)
        let bushPositions: [CGFloat] = [80, 200, 380, 560, 740, 950, 1180, 1420, 1640, 1900, 2200, 2500, 2800]
        for x in bushPositions {
            let bush = SKShapeNode(ellipseOf: CGSize(width: CGFloat.random(in: 22...36), height: CGFloat.random(in: 14...22)))
            bush.fillColor = UIColor(hex: "#1e5c14")
            bush.strokeColor = .clear
            bush.position = CGPoint(x: x, y: groundY)
            bush.zPosition = 1
            addChild(bush)
        }

        // Foreground trees (larger)
        let treePositions: [CGFloat] = [160, 440, 830, 1250, 1700, 2100, 2600]
        for x in treePositions {
            let h: CGFloat = CGFloat.random(in: 80...140)
            let tree = makePixelTree(height: h, color: UIColor(hex: "#1e5c14"))
            tree.position = CGPoint(x: x, y: groundY + 10)
            tree.zPosition = 2
            addChild(tree)
        }

        // Torch lights near clue spots
        for x: CGFloat in [490, 1820] {
            addTorch(at: CGPoint(x: x, y: groundY + 24))
        }
    }

    private func placeCollectibles(heights: [Int]) {
        let ts = tileSize

        // Gold coins in arcs
        let coinArcs: [(x: CGFloat, y: CGFloat)] = [
            (180, ts*5+20), (220, ts*5+40), (260, ts*5+20),
            (600, ts*4+20), (640, ts*4+30), (680, ts*4+20), (720, ts*4+20),
            (900, ts*5+20), (940, ts*5+30), (980, ts*5+20),
            (1200, ts*5+20), (1240, ts*5+35), (1280, ts*5+20),
            (1600, ts*4+20), (1640, ts*4+20),
            (2000, ts*5+20), (2040, ts*5+30), (2080, ts*5+20), (2120, ts*5+20),
            (2500, ts*5+20), (2540, ts*5+20),
            (2700, ts*5+20), (2740, ts*5+30), (2780, ts*5+20),
        ]
        for pos in coinArcs {
            let coin = CollectibleNode(type: .gold)
            coin.position = pos
            coin.zPosition = 3
            addChild(coin)
        }

        // Artifacts (rare — 3 in level)
        for pos: CGPoint in [
            CGPoint(x: 830,  y: ts*10+20),
            CGPoint(x: 1780, y: ts*5+20),
            CGPoint(x: 2900, y: ts*5+20),
        ] {
            let artifact = CollectibleNode(type: .artifact)
            artifact.position = pos
            artifact.zPosition = 3
            addChild(artifact)
        }
    }

    private func placeEnemies() {
        let ts = tileSize
        let groundY = ts * 4 + ts / 2

        let defs: [(x: CGFloat, patrol: CGFloat)] = [
            (650,  100), (1050, 120), (1500, 90),
            (2000, 110), (2400, 130), (2800, 100),
        ]
        for def in defs {
            let enemy = EnemyNode(patrolDistance: def.patrol)
            enemy.position = CGPoint(x: def.x, y: groundY)
            enemy.zPosition = 3
            enemies.append(enemy)
            addChild(enemy)
        }
    }

    private func placeClues() {
        let ts = tileSize
        let groundY = ts * 4 + ts / 2 + 2

        let clueData: [(Clue, CGPoint)] = [
            (Clue.allClues[0], CGPoint(x: 490,  y: groundY + 16)),
            (Clue.allClues[1], CGPoint(x: 1820, y: groundY + 16)),
        ]
        for (clue, pos) in clueData {
            let node = ClueNode(clue: clue)
            node.position = pos
            node.zPosition = 3
            addChild(node)
        }
    }

    private func buildTemple(x: CGFloat) {
        let ts = tileSize
        let groundY = ts * 4 + ts / 2

        // Base
        let baseW: CGFloat = 120, baseH: CGFloat = 120
        let base = SKShapeNode(rectOf: CGSize(width: baseW, height: baseH), cornerRadius: 4)
        base.fillColor = UIColor(hex: "#5c4a28")
        base.strokeColor = UIColor(hex: "#f5c842")
        base.lineWidth = 2
        base.position = CGPoint(x: x, y: groundY + baseH/2)
        base.zPosition = 4
        addChild(base)

        // Pyramid
        let pyramidPath = CGMutablePath()
        pyramidPath.move(to: CGPoint(x: -80, y: 0))
        pyramidPath.addLine(to: CGPoint(x: 80, y: 0))
        pyramidPath.addLine(to: CGPoint(x: 0, y: 100))
        pyramidPath.closeSubpath()
        let pyramid = SKShapeNode(path: pyramidPath)
        pyramid.fillColor = UIColor(hex: "#5c4a28")
        pyramid.strokeColor = UIColor(hex: "#f5c842")
        pyramid.lineWidth = 2
        pyramid.position = CGPoint(x: x, y: groundY + baseH)
        pyramid.zPosition = 4
        addChild(pyramid)

        // Gold top + glow
        let glow = SKShapeNode(circleOfRadius: 22)
        glow.fillColor = UIColor(hex: "#f5c842").withAlphaComponent(0.3)
        glow.strokeColor = .clear
        glow.position = CGPoint(x: x, y: groundY + baseH + 100)
        glow.zPosition = 5
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.4, duration: 0.9),
            SKAction.scale(to: 1.0, duration: 0.9),
        ])
        glow.run(SKAction.repeatForever(pulse))
        addChild(glow)

        let top = SKShapeNode(circleOfRadius: 10)
        top.fillColor = UIColor(hex: "#f5c842")
        top.strokeColor = .clear
        top.position = CGPoint(x: x, y: groundY + baseH + 100)
        top.zPosition = 6
        addChild(top)

        // Door
        let door = SKShapeNode(rectOf: CGSize(width: 28, height: 50))
        door.fillColor = UIColor(hex: "#0d1b2a")
        door.strokeColor = UIColor(hex: "#f5c842").withAlphaComponent(0.5)
        door.lineWidth = 1
        door.position = CGPoint(x: x, y: groundY + 25)
        door.zPosition = 5
        addChild(door)

        // Invisible level-end trigger
        let trigger = SKNode()
        let trigBody = SKPhysicsBody(rectangleOf: CGSize(width: 50, height: 200))
        trigBody.isDynamic = false
        trigBody.categoryBitMask = Cat.levelEnd
        trigBody.contactTestBitMask = Cat.player
        trigBody.collisionBitMask = 0
        trigger.physicsBody = trigBody
        trigger.position = CGPoint(x: x, y: groundY + 100)
        addChild(trigger)
    }

    // MARK: Player / Camera / HUD
    private func setupPlayer() {
        player = PlayerNode()
        player.position = CGPoint(x: 80, y: tileSize * 5 + 20)
        player.zPosition = 10
        addChild(player)
    }

    private func setupCamera() {
        cam = SKCameraNode()
        camera = cam
        cam.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(cam)
    }

    private func setupHUD() {
        hud = HUDNode(viewSize: size)
        hud.zPosition = 50
        cam.addChild(hud)
    }

    private func setupControls() {
        controls = ControlsNode(viewSize: size)
        controls.zPosition = 60

        controls.onLeft        = { [weak self] in self?.isMovingLeft  = true  }
        controls.onLeftRelease = { [weak self] in self?.isMovingLeft  = false }
        controls.onRight       = { [weak self] in self?.isMovingRight = true  }
        controls.onRightRelease = { [weak self] in self?.isMovingRight = false }
        controls.onJump        = { [weak self] in self?.player.jump()         }

        cam.addChild(controls)
    }

    // MARK: - Update loop

    override func update(_ currentTime: TimeInterval) {
        guard !levelDone else { return }

        // Player movement
        if isMovingLeft       { player.moveLeft()  }
        else if isMovingRight { player.moveRight() }
        else                  { player.stopHorizontal() }

        // Clamp velocity
        if let vy = player.physicsBody?.velocity.dy, vy < -1200 {
            player.physicsBody?.velocity.dy = -1200
        }

        // Camera follow (lerp)
        let halfW = size.width  / 2
        let halfH = size.height / 2
        let targetX = max(halfW, min(player.position.x, worldWidth - halfW))
        let targetY = halfH
        cam.position.x += (targetX - cam.position.x) * 0.12
        cam.position.y = targetY

        // Enemy patrol
        for enemy in enemies { enemy.patrol() }

        // Fall into pit
        if player.position.y < -80 { respawnPlayer() }
    }

    // MARK: - Contacts

    func didBegin(_ contact: SKPhysicsContact) {
        let (a, b) = sortedBodies(contact)

        switch (a.categoryBitMask, b.categoryBitMask) {

        case (Cat.player, Cat.ground):
            player.setGrounded(true)

        case (Cat.player, Cat.collectible):
            if let node = b.node as? CollectibleNode {
                handleCollectible(node)
            }

        case (Cat.player, Cat.enemy):
            handleEnemyContact()

        case (Cat.player, Cat.clue):
            if let node = b.node as? ClueNode {
                handleClue(node)
            }

        case (Cat.player, Cat.levelEnd):
            handleLevelEnd()

        default: break
        }
    }

    func didEnd(_ contact: SKPhysicsContact) {
        let (a, b) = sortedBodies(contact)
        if a.categoryBitMask == Cat.player && b.categoryBitMask == Cat.ground {
            // Check if still on any ground
            let onGround = player.physicsBody.flatMap { $0.allContactedBodies().contains { $0.categoryBitMask == Cat.ground } } ?? false
            if !onGround { player.setGrounded(false) }
        }
    }

    private func sortedBodies(_ contact: SKPhysicsContact) -> (SKPhysicsBody, SKPhysicsBody) {
        if contact.bodyA.categoryBitMask <= contact.bodyB.categoryBitMask {
            return (contact.bodyA, contact.bodyB)
        }
        return (contact.bodyB, contact.bodyA)
    }

    private func handleCollectible(_ node: CollectibleNode) {
        node.collect(in: self)
        switch node.collectibleType {
        case .gold:
            goldCount += 1
            hud.updateGold(goldCount)
            onGoldCollected?(1)
            hud.showFloatingText("+10", at: node.position)
        case .artifact:
            onArtifactCollected?()
            hud.showFloatingText("🏺 ARTIFACT!", at: node.position, color: UIColor(hex: "#c0822e"))
        }
    }

    private func handleEnemyContact() {
        guard !invincible else { return }
        invincible = true
        tookDamage = true
        player.playHitEffect()
        hud.loseLife()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            self?.invincible = false
        }
    }

    private func handleClue(_ node: ClueNode) {
        node.examine()
        onClueFound?(node.clue)
        showCluePopup(clue: node.clue, at: node.position)
    }

    private func handleLevelEnd() {
        guard !levelDone else { return }
        levelDone = true
        isPaused = true

        let elapsed = Date().timeIntervalSince1970 - levelStartTime
        onLevelComplete?(elapsed, !tookDamage)

        showVictoryBanner()
    }

    // MARK: - UI Popups

    private func showCluePopup(clue: Clue, at position: CGPoint) {
        let panel = SKShapeNode(rectOf: CGSize(width: 280, height: 160), cornerRadius: 12)
        panel.fillColor = UIColor(hex: "#0d1b2a").withAlphaComponent(0.96)
        panel.strokeColor = UIColor(hex: "#9b59b6")
        panel.lineWidth = 2
        panel.position = CGPoint(x: 0, y: 40)
        panel.zPosition = 80
        cam.addChild(panel)

        let symbol = SKLabelNode(text: clue.symbol)
        symbol.fontSize = 28
        symbol.verticalAlignmentMode = .center
        symbol.position = CGPoint(x: 0, y: 50)
        panel.addChild(symbol)

        let title = SKLabelNode(text: clue.title)
        title.fontName = "Courier-Bold"
        title.fontSize = 14
        title.fontColor = UIColor(hex: "#f5c842")
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: 22)
        panel.addChild(title)

        let desc = SKLabelNode(text: clue.description)
        desc.fontName = "Courier"
        desc.fontSize = 10
        desc.fontColor = UIColor.white.withAlphaComponent(0.8)
        desc.numberOfLines = 3
        desc.preferredMaxLayoutWidth = 250
        desc.verticalAlignmentMode = .center
        desc.horizontalAlignmentMode = .center
        desc.position = CGPoint(x: 0, y: -10)
        panel.addChild(desc)

        let hint = SKLabelNode(text: "📓 Added to journal")
        hint.fontName = "Courier"
        hint.fontSize = 9
        hint.fontColor = UIColor(hex: "#9b59b6")
        hint.verticalAlignmentMode = .center
        hint.position = CGPoint(x: 0, y: -60)
        panel.addChild(hint)

        panel.run(SKAction.sequence([
            SKAction.wait(forDuration: 3.5),
            SKAction.fadeOut(withDuration: 0.4),
            SKAction.removeFromParent(),
        ]))
    }

    private func showVictoryBanner() {
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        overlay.fillColor = UIColor(hex: "#0d1b2a").withAlphaComponent(0)
        overlay.strokeColor = .clear
        overlay.position = .zero
        overlay.zPosition = 90
        cam.addChild(overlay)

        overlay.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.6, duration: 0.5),
        ]))

        let trophy = SKLabelNode(text: "🏆")
        trophy.fontSize = 56
        trophy.verticalAlignmentMode = .center
        trophy.position = CGPoint(x: 0, y: 50)
        trophy.zPosition = 91
        cam.addChild(trophy)
        trophy.setScale(0)
        trophy.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            SKAction.scale(to: 1.2, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.15),
        ]))

        let title = SKLabelNode(text: "LEVEL COMPLETE!")
        title.fontName = "Courier-Bold"
        title.fontSize = 26
        title.fontColor = UIColor(hex: "#f5c842")
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: -20)
        title.zPosition = 91
        cam.addChild(title)

        let sub = SKLabelNode(text: !tookDamage ? "🛡️ NO DAMAGE!" : "Keep exploring!")
        sub.fontName = "Courier"
        sub.fontSize = 14
        sub.fontColor = UIColor.white.withAlphaComponent(0.75)
        sub.verticalAlignmentMode = .center
        sub.position = CGPoint(x: 0, y: -58)
        sub.zPosition = 91
        cam.addChild(sub)
    }

    // MARK: - Respawn
    private func respawnPlayer() {
        player.position = CGPoint(x: 80, y: tileSize * 5 + 20)
        player.physicsBody?.velocity = .zero
        if !invincible {
            invincible = true
            tookDamage = true
            hud.loseLife()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in self?.invincible = false }
        }
    }

    // MARK: - Helpers

    private func makePixelTree(height: CGFloat, color: UIColor) -> SKNode {
        let tree = SKNode()

        let trunk = SKShapeNode(rectOf: CGSize(width: height * 0.12, height: height * 0.38))
        trunk.fillColor = UIColor(hex: "#3d1a05")
        trunk.strokeColor = .clear
        trunk.position = CGPoint(x: 0, y: height * 0.19)
        tree.addChild(trunk)

        for (i, scale): (Int, CGFloat) in [(0, 1.0), (1, 0.75), (2, 0.5)] {
            let canopy = SKShapeNode(rectOf: CGSize(width: height * 0.55 * scale, height: height * 0.32 * scale), cornerRadius: 4)
            canopy.fillColor = color
            canopy.strokeColor = .clear
            canopy.position = CGPoint(x: 0, y: height * (0.55 + CGFloat(i) * 0.16))
            tree.addChild(canopy)
        }

        return tree
    }

    private func addTorch(at position: CGPoint) {
        let stick = SKShapeNode(rectOf: CGSize(width: 5, height: 22))
        stick.fillColor = UIColor(hex: "#5c3a1e")
        stick.strokeColor = .clear
        stick.position = position
        stick.zPosition = 4
        addChild(stick)

        let flame = SKShapeNode(ellipseOf: CGSize(width: 10, height: 14))
        flame.fillColor = UIColor(hex: "#ff6b35")
        flame.strokeColor = .clear
        flame.position = CGPoint(x: position.x, y: position.y + 18)
        flame.zPosition = 5
        addChild(flame)

        let flicker = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.12),
            SKAction.scale(to: 0.9, duration: 0.12),
            SKAction.scale(to: 1.0, duration: 0.1),
        ])
        flame.run(SKAction.repeatForever(flicker))

        let glow = SKShapeNode(circleOfRadius: 24)
        glow.fillColor = UIColor(hex: "#ff6b35").withAlphaComponent(0.18)
        glow.strokeColor = .clear
        glow.position = CGPoint(x: position.x, y: position.y + 18)
        glow.zPosition = 3
        addChild(glow)
    }
}
