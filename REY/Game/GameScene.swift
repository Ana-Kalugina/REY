import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: - Callbacks
    var onGoldCollected:     ((Int) -> Void)?
    var onArtifactCollected: (() -> Void)?
    var onClueFound:         ((Clue) -> Void)?
    var onLevelComplete:     ((Double, Bool) -> Void)?

    // MARK: - Physics categories
    struct Cat {
        static let player:      UInt32 = 0x1 << 0
        static let ground:      UInt32 = 0x1 << 1
        static let collectible: UInt32 = 0x1 << 2
        static let enemy:       UInt32 = 0x1 << 3
        static let clue:        UInt32 = 0x1 << 4
        static let levelEnd:    UInt32 = 0x1 << 5
    }

    // MARK: - Nodes
    private var player:   PlayerNode!
    private var cam:      SKCameraNode!
    private var hud:      HUDNode!
    private var controls: ControlsNode!
    private var tutorial: TutorialNode?
    private var enemies:  [EnemyNode] = []

    // MARK: - State
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
        backgroundColor = UIColor(hex: "#100820")
        setupPhysics()
        buildBackground()
        buildLevel()
        setupPlayer()
        setupCamera()
        setupHUD()
        setupControls()
        setupTutorialIfNeeded()
        levelStartTime = Date().timeIntervalSince1970
    }

    private func setupPhysics() {
        physicsWorld.gravity         = CGVector(dx: 0, dy: -12)
        physicsWorld.contactDelegate = self
        physicsBody = SKPhysicsBody(
            edgeLoopFrom: CGRect(x: 0, y: -100, width: worldWidth, height: size.height + 200)
        )
    }

    // MARK: - Rich Background (Rayman/Tarzan style)

    private func buildBackground() {
        drawSkyGradient()
        addStars()
        addMoon()
        addDistantHills()
        addParallaxJungle()
    }

    private func drawSkyGradient() {
        let bands: [(String, CGFloat)] = [
            ("#100820", 0.0), ("#1a0d38", 0.18), ("#0c1e3a", 0.36),
            ("#0a2230", 0.54), ("#0a2818", 0.72), ("#0c3018", 0.88),
        ]
        for (hex, frac) in bands {
            let h = size.height / CGFloat(bands.count) + 2
            let strip = SKSpriteNode(
                color: UIColor(hex: hex),
                size: CGSize(width: worldWidth + 200, height: h)
            )
            strip.anchorPoint = .zero
            strip.position    = CGPoint(x: -100, y: size.height * frac)
            strip.zPosition   = -22
            addChild(strip)
        }
    }

    private func addStars() {
        for _ in 0..<180 {
            let r = CGFloat.random(in: 0.4...2.5)
            let star = SKShapeNode(circleOfRadius: r)
            star.fillColor   = .white
            star.strokeColor = .clear
            star.position    = CGPoint(
                x: CGFloat.random(in: 0...worldWidth),
                y: CGFloat.random(in: size.height * 0.45...size.height * 1.02)
            )
            star.alpha     = CGFloat.random(in: 0.12...0.9)
            star.zPosition = -21
            addChild(star)

            if Bool.random() {
                let twinkle = SKAction.repeatForever(SKAction.sequence([
                    SKAction.fadeAlpha(to: CGFloat.random(in: 0.05...0.2), duration: Double.random(in: 1.2...3.5)),
                    SKAction.fadeAlpha(to: CGFloat.random(in: 0.6...1.0),  duration: Double.random(in: 1.2...3.5)),
                ]))
                star.run(twinkle)
            }
        }
    }

    private func addMoon() {
        let cx = worldWidth * 0.82
        let cy = size.height * 0.86

        // Atmospheric halo layers
        for (radius, alpha): (CGFloat, CGFloat) in [(80, 0.04), (58, 0.08), (42, 0.13)] {
            let halo = SKShapeNode(circleOfRadius: radius)
            halo.fillColor   = UIColor(hex: "#dce8ff").withAlphaComponent(alpha)
            halo.strokeColor = .clear
            halo.position    = CGPoint(x: cx, y: cy)
            halo.zPosition   = -20
            addChild(halo)
        }

        // Moon disc
        let moon = SKShapeNode(circleOfRadius: 30)
        moon.fillColor   = UIColor(hex: "#f0e8d8")
        moon.strokeColor = UIColor(hex: "#e8d8b8").withAlphaComponent(0.4)
        moon.lineWidth   = 1.5
        moon.position    = CGPoint(x: cx, y: cy)
        moon.zPosition   = -19
        addChild(moon)

        // Craters
        for (ox, oy, r): (CGFloat, CGFloat, CGFloat) in [(-8, 8, 5), (10, -6, 4), (-2, -10, 3)] {
            let crater = SKShapeNode(circleOfRadius: r)
            crater.fillColor   = UIColor(hex: "#d8c8a8")
            crater.strokeColor = .clear
            crater.position    = CGPoint(x: cx + ox, y: cy + oy)
            crater.zPosition   = -18
            addChild(crater)
        }
    }

    private func addDistantHills() {
        // Smooth rolling silhouette hills
        let path  = CGMutablePath()
        let baseY = size.height * 0.5
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: baseY))

        let peaks: [(CGFloat, CGFloat)] = [
            (240, 55), (500, 90), (760, 62), (1020, 100),
            (1280, 70), (1560, 88), (1840, 58), (2120, 95),
            (2400, 68), (2680, 82), (2960, 52), (3200, 0),
        ]
        var prev: (CGFloat, CGFloat) = (0, baseY)
        for (x, rise) in peaks {
            path.addCurve(
                to: CGPoint(x: x, y: baseY + rise),
                control1: CGPoint(x: prev.0 + 80, y: baseY + prev.1 - baseY),
                control2: CGPoint(x: x - 80, y: baseY + rise)
            )
            prev = (x, rise)
        }
        path.addLine(to: CGPoint(x: 3200, y: 0))
        path.closeSubpath()

        let hills = SKShapeNode(path: path)
        hills.fillColor = UIColor(hex: "#060f06")
        hills.strokeColor = .clear
        hills.zPosition = -17
        addChild(hills)
    }

    private func addParallaxJungle() {
        // 4 depth layers of jungle trees, progressively brighter
        let layers: [(count: Int, colorHex: String, minH: CGFloat, maxH: CGFloat, z: CGFloat)] = [
            (38, "#050d08",  40,  80, -15),
            (30, "#081408",  55, 100, -13),
            (24, "#0c1e0c",  70, 130, -11),
            (18, "#122412",  90, 160,  -9),
        ]
        let groundY = tileSize * 4 + tileSize / 2
        for layer in layers {
            let spacing = worldWidth / CGFloat(layer.count)
            for i in 0..<layer.count {
                let h = CGFloat.random(in: layer.minH...layer.maxH)
                let node = makeRaymanTree(
                    height: h,
                    dark:   UIColor(hex: layer.colorHex),
                    mid:    UIColor(hex: layer.colorHex).withAlphaComponent(0.9),
                    light:  UIColor(hex: layer.colorHex)
                )
                node.position  = CGPoint(
                    x: CGFloat(i) * spacing + CGFloat.random(in: -18...18),
                    y: groundY
                )
                node.zPosition = layer.z
                addChild(node)
            }
        }
    }

    // MARK: - Level Geometry

    private func buildLevel() {
        let ts   = tileSize
        let cols = Int(worldWidth / ts)
        var heights = [Int](repeating: 4, count: cols)

        // Pit gaps
        for start in [18, 35, 55, 68] {
            for i in start..<(start + 3) { if i < cols { heights[i] = 0 } }
        }
        for i in stride(from: 0, to: cols, by: 7) {
            if heights[i] > 0 { heights[i] = 5 }
        }

        for (x, h) in heights.enumerated() {
            guard h > 0 else { continue }
            for y in 0..<h {
                let tile = makeTile(isTop: y == h - 1, isGround: true)
                tile.position = CGPoint(x: CGFloat(x) * ts + ts/2, y: CGFloat(y) * ts + ts/2)
                addChild(tile)
            }
        }

        // Floating platforms
        let platforms: [(Int, Int, Int)] = [
            (6, 7, 4), (14, 9, 3), (21, 7, 5), (29, 10, 4),
            (37, 8, 4), (44, 11, 5), (51, 9, 4), (59, 8, 3),
            (64, 12, 4), (70, 9, 3), (74, 7, 4),
        ]
        for (px, py, pw) in platforms {
            for i in 0..<pw {
                let tile = makeTile(isTop: true, isGround: false)
                tile.position = CGPoint(
                    x: CGFloat(px + i) * ts + ts/2,
                    y: CGFloat(py) * ts + ts/2
                )
                addChild(tile)
            }
        }

        placeDecoration()
        placeCollectibles()
        placeEnemies()
        placeClues()
        buildTemple(x: worldWidth - 140)
        addFireflies()
        addGroundMist()
    }

    // MARK: Beautiful tile (gradient + organic grass)
    private func makeTile(isTop: Bool, isGround: Bool) -> SKSpriteNode {
        let ts = tileSize
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: ts, height: ts))
        let img = renderer.image { ctx in
            let c = ctx.cgContext

            if isTop {
                // Earth body
                gradV(c, from: UIColor(hex: "#3e1a08"), to: UIColor(hex: "#5c2e10"),
                      rect: CGRect(x: 0, y: 0, width: ts, height: ts - 11))
                // Grass layer
                gradV(c, from: UIColor(hex: "#3a9228"), to: UIColor(hex: "#5cbf3e"),
                      rect: CGRect(x: 0, y: ts - 11, width: ts, height: 11))

                if isGround {
                    // Organic grass blades
                    c.setFillColor(UIColor(hex: "#78e050").cgColor)
                    for xi in stride(from: 1.5, through: ts - 4, by: 6.5) {
                        let blade = CGMutablePath()
                        blade.move(to:  CGPoint(x: xi, y: ts - 8))
                        blade.addQuadCurve(to: CGPoint(x: xi + 2, y: ts + 1),
                                           control: CGPoint(x: xi - 1, y: ts - 2))
                        blade.addQuadCurve(to: CGPoint(x: xi + 5, y: ts - 8),
                                           control: CGPoint(x: xi + 6, y: ts - 2))
                        c.addPath(blade)
                        c.fillPath()
                    }
                } else {
                    // Platform top: moss patches
                    c.setFillColor(UIColor(hex: "#5a9a3a").withAlphaComponent(0.6).cgColor)
                    for xi in stride(from: 2.0, through: ts - 6, by: 9.0) {
                        c.fillEllipse(in: CGRect(x: xi, y: ts - 10, width: 6, height: 4))
                    }
                }
            } else {
                gradV(c, from: UIColor(hex: "#2e1008"), to: UIColor(hex: "#4a2010"),
                      rect: CGRect(x: 0, y: 0, width: ts, height: ts))

                // Root vein
                c.setStrokeColor(UIColor(hex: "#1a0805").withAlphaComponent(0.45).cgColor)
                c.setLineWidth(1.2)
                let vein = CGMutablePath()
                vein.move(to: CGPoint(x: ts * 0.35, y: ts))
                vein.addCurve(to: CGPoint(x: ts * 0.55, y: ts * 0.4),
                              control1: CGPoint(x: ts * 0.2, y: ts * 0.7),
                              control2: CGPoint(x: ts * 0.65, y: ts * 0.55))
                vein.addCurve(to: CGPoint(x: ts * 0.42, y: 0),
                              control1: CGPoint(x: ts * 0.48, y: ts * 0.25),
                              control2: CGPoint(x: ts * 0.45, y: 0.1))
                c.addPath(vein); c.strokePath()
            }
        }

        let node = SKSpriteNode(texture: SKTexture(image: img), size: CGSize(width: ts, height: ts))
        let body = SKPhysicsBody(rectangleOf: CGSize(width: ts, height: ts))
        body.isDynamic           = false
        body.categoryBitMask     = Cat.ground
        body.collisionBitMask    = Cat.player | Cat.enemy
        body.contactTestBitMask  = Cat.player
        body.friction            = 0.3
        node.physicsBody         = body
        node.zPosition           = 0
        return node
    }

    private func gradV(_ c: CGContext, from: UIColor, to: UIColor, rect: CGRect) {
        guard let g = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [from.cgColor, to.cgColor] as CFArray,
            locations: [0, 1]
        ) else { return }
        c.clip(to: rect)
        c.drawLinearGradient(g,
                             start: CGPoint(x: rect.midX, y: rect.minY),
                             end:   CGPoint(x: rect.midX, y: rect.maxY),
                             options: [])
        c.resetClip()
    }

    // MARK: Rayman-style multi-oval tree
    private func makeRaymanTree(height h: CGFloat, dark: UIColor, mid: UIColor, light: UIColor) -> SKNode {
        let tree   = SKNode()
        let trunkH = h * 0.42
        let trunkW = h * 0.13
        let cH     = h - trunkH
        let canopyY = trunkH + cH * 0.15

        // Trunk
        let trunk = SKShapeNode(
            rectOf: CGSize(width: trunkW, height: trunkH),
            cornerRadius: trunkW / 2.5
        )
        trunk.fillColor   = UIColor(hex: "#3a1a05").withAlphaComponent(dark.cgColor.alpha > 0.4 ? 0.9 : 0.5)
        trunk.strokeColor = .clear
        trunk.position    = CGPoint(x: 0, y: trunkH / 2)
        tree.addChild(trunk)

        // Multi-oval canopy layers (key to Rayman look)
        let ovals: [(ox: CGFloat, oy: CGFloat, w: CGFloat, h2: CGFloat, color: UIColor)] = [
            (0,         canopyY,          cH * 0.90, cH * 0.60, dark),
            (0,         canopyY + cH*0.08, cH * 0.72, cH * 0.52, mid),
            (-cH*0.28,  canopyY - cH*0.04, cH * 0.52, cH * 0.40, mid),
            ( cH*0.26,  canopyY - cH*0.02, cH * 0.48, cH * 0.38, mid),
            ( cH*0.06,  canopyY + cH*0.22, cH * 0.50, cH * 0.38, light),
            (-cH*0.08,  canopyY + cH*0.30, cH * 0.32, cH * 0.26, light),
        ]
        for o in ovals {
            let oval = SKShapeNode(ellipseOf: CGSize(width: o.w, height: o.h2))
            oval.fillColor   = o.color
            oval.strokeColor = .clear
            oval.position    = CGPoint(x: o.ox, y: o.oy)
            tree.addChild(oval)
        }
        return tree
    }

    // MARK: Decorations
    private func placeDecoration() {
        let ts      = tileSize
        let groundY = ts * 4 + ts / 2 + 14

        // Foreground lush trees (visible colour)
        let treeSpots: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (140,  90, 0.18, 0.5),  (420, 110, 0.22, 0.6),
            (820, 130, 0.28, 0.7),  (1240, 100, 0.20, 0.55),
            (1680, 120, 0.25, 0.65),(2080, 105, 0.21, 0.58),
            (2580, 125, 0.26, 0.68),(3000, 90, 0.18, 0.5),
        ]
        let fgColors: [(String, String, String)] = [
            ("#1a5c14","#28802a","#4ab040"),
            ("#155018","#228030","#38a838"),
            ("#1c5c10","#2a8025","#48b035"),
        ]
        for (i, (x, h, _, _)) in treeSpots.enumerated() {
            let c = fgColors[i % fgColors.count]
            let tree = makeRaymanTree(
                height: h,
                dark:  UIColor(hex: c.0),
                mid:   UIColor(hex: c.1),
                light: UIColor(hex: c.2)
            )
            tree.position  = CGPoint(x: x, y: groundY)
            tree.zPosition = 2
            addChild(tree)
        }

        // Ground bushes
        let bushX: [CGFloat] = [90, 310, 550, 760, 1060, 1360, 1600, 1950, 2300, 2700]
        for x in bushX {
            let w = CGFloat.random(in: 28...50)
            let bush = SKShapeNode(ellipseOf: CGSize(width: w, height: w * 0.55))
            bush.fillColor   = UIColor(hex: "#226018")
            bush.strokeColor = .clear
            bush.position    = CGPoint(x: x, y: groundY - 4)
            bush.zPosition   = 1
            addChild(bush)

            let bushhigh = SKShapeNode(ellipseOf: CGSize(width: w * 0.55, height: w * 0.35))
            bushhigh.fillColor   = UIColor(hex: "#30882a").withAlphaComponent(0.7)
            bushhigh.strokeColor = .clear
            bushhigh.position    = CGPoint(x: x + CGFloat.random(in: -4...4), y: groundY + 2)
            bushhigh.zPosition   = 1
            addChild(bushhigh)
        }

        // Torches at clue locations
        for x: CGFloat in [490, 1820] {
            addTorch(at: CGPoint(x: x, y: groundY + 26))
        }
    }

    private func addFireflies() {
        for _ in 0..<48 {
            let ff = SKNode()

            let glow = SKShapeNode(circleOfRadius: 5)
            glow.fillColor   = UIColor(hex: "#b0ff70").withAlphaComponent(0.28)
            glow.strokeColor = .clear

            let core = SKShapeNode(circleOfRadius: 1.8)
            core.fillColor   = UIColor(hex: "#d8ffb0")
            core.strokeColor = .clear
            glow.addChild(core)
            ff.addChild(glow)

            ff.position  = CGPoint(
                x: CGFloat.random(in: 60...worldWidth - 60),
                y: CGFloat.random(in: tileSize * 3.5...tileSize * 10)
            )
            ff.zPosition = 6
            addChild(ff)

            let dur   = Double.random(in: 2.5...6.5)
            let dx    = CGFloat.random(in: -55...55)
            let dy    = CGFloat.random(in: -22...22)
            ff.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.moveBy(x: dx, y: dy, duration: dur),
                SKAction.moveBy(x: -dx, y: -dy, duration: dur),
            ])))

            let delay = Double.random(in: 0...3)
            glow.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.fadeAlpha(to: 0.04, duration: Double.random(in: 0.4...1.3)),
                SKAction.fadeAlpha(to: 0.85, duration: Double.random(in: 0.4...1.3)),
            ])))
        }
    }

    private func addGroundMist() {
        for i in 0..<12 {
            let w    = CGFloat.random(in: 320...580)
            let mist = SKSpriteNode(
                color: UIColor(hex: "#80d8c0").withAlphaComponent(0.045),
                size: CGSize(width: w, height: 32)
            )
            mist.anchorPoint = CGPoint(x: 0, y: 0.5)
            mist.position    = CGPoint(
                x: CGFloat(i) * 300 + CGFloat.random(in: -40...40),
                y: tileSize * 4 + CGFloat.random(in: 6...28)
            )
            mist.zPosition = 4

            mist.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.moveBy(x: CGFloat.random(in: 20...45), y: 0, duration: Double.random(in: 3...6)),
                SKAction.moveBy(x: -CGFloat.random(in: 20...45), y: 0, duration: Double.random(in: 3...6)),
            ])))
            mist.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.015, duration: Double.random(in: 2...4)),
                SKAction.fadeAlpha(to: 0.07,  duration: Double.random(in: 2...4)),
            ])))
            addChild(mist)
        }
    }

    private func placeCollectibles() {
        let ts = tileSize
        let coinPositions: [(CGFloat, CGFloat)] = [
            (180, ts*5+24), (220, ts*5+44), (260, ts*5+24),
            (600, ts*4+24), (640, ts*4+34), (680, ts*4+24), (720, ts*4+24),
            (900, ts*5+24), (940, ts*5+34), (980, ts*5+24),
            (1200, ts*5+24), (1240, ts*5+38), (1280, ts*5+24),
            (1600, ts*4+24), (1640, ts*4+24),
            (2000, ts*5+24), (2040, ts*5+34), (2080, ts*5+24), (2120, ts*5+24),
            (2500, ts*5+24), (2540, ts*5+24),
            (2700, ts*5+24), (2740, ts*5+34), (2780, ts*5+24),
        ]
        for (x, y) in coinPositions {
            let c = CollectibleNode(type: .gold)
            c.position  = CGPoint(x: x, y: y)
            c.zPosition = 3
            addChild(c)
        }

        for pos: CGPoint in [
            CGPoint(x: 830,  y: ts*10+24),
            CGPoint(x: 1780, y: ts*5+24),
            CGPoint(x: 2900, y: ts*5+24),
        ] {
            let a = CollectibleNode(type: .artifact)
            a.position  = pos
            a.zPosition = 3
            addChild(a)
        }
    }

    private func placeEnemies() {
        let ts      = tileSize
        let groundY = ts * 4 + ts / 2
        for (x, patrol): (CGFloat, CGFloat) in [
            (650, 100), (1050, 120), (1500, 90),
            (2000, 110), (2400, 130), (2800, 100),
        ] {
            let e = EnemyNode(patrolDistance: patrol)
            e.position  = CGPoint(x: x, y: groundY)
            e.zPosition = 3
            enemies.append(e)
            addChild(e)
        }
    }

    private func placeClues() {
        let ts      = tileSize
        let groundY = ts * 4 + ts / 2 + 2
        for (clue, pos): (Clue, CGPoint) in [
            (Clue.allClues[0], CGPoint(x: 490,  y: groundY + 18)),
            (Clue.allClues[1], CGPoint(x: 1820, y: groundY + 18)),
        ] {
            let n = ClueNode(clue: clue)
            n.position  = pos
            n.zPosition = 3
            addChild(n)
        }
    }

    // MARK: Atmospheric temple
    private func buildTemple(x: CGFloat) {
        let ts      = tileSize
        let groundY = ts * 4 + ts / 2

        // Vine curtains
        for vx: CGFloat in [-60, -30, 30, 60] {
            for segment in 0..<6 {
                let vine = SKShapeNode(circleOfRadius: 2.5)
                vine.fillColor   = UIColor(hex: "#1e5c14")
                vine.strokeColor = .clear
                vine.position    = CGPoint(x: x + vx, y: groundY + 20 + CGFloat(segment) * 22)
                vine.zPosition   = 3
                addChild(vine)
            }
        }

        // Base pillar pair
        for px: CGFloat in [-50, 50] {
            let pillar = SKShapeNode(rectOf: CGSize(width: 18, height: 130), cornerRadius: 3)
            pillar.fillColor   = UIColor(hex: "#4a3820")
            pillar.strokeColor = UIColor(hex: "#f5c842").withAlphaComponent(0.35)
            pillar.lineWidth   = 1
            pillar.position    = CGPoint(x: x + px, y: groundY + 65)
            pillar.zPosition   = 4
            addChild(pillar)

            // Pillar highlight
            let shine = SKShapeNode(rectOf: CGSize(width: 5, height: 120), cornerRadius: 2)
            shine.fillColor   = UIColor(hex: "#7a6040").withAlphaComponent(0.4)
            shine.strokeColor = .clear
            shine.position    = CGPoint(x: x + px - 5, y: groundY + 65)
            shine.zPosition   = 4
            addChild(shine)
        }

        // Main base
        let base = SKShapeNode(rectOf: CGSize(width: 130, height: 130), cornerRadius: 6)
        base.fillColor   = UIColor(hex: "#3a2c14")
        base.strokeColor = UIColor(hex: "#f5c842").withAlphaComponent(0.5)
        base.lineWidth   = 2
        base.position    = CGPoint(x: x, y: groundY + 65)
        base.zPosition   = 4
        addChild(base)

        // Base stone texture lines
        for li in 1..<4 {
            let line = SKShapeNode(rectOf: CGSize(width: 120, height: 1))
            line.fillColor   = UIColor(hex: "#f5c842").withAlphaComponent(0.08)
            line.strokeColor = .clear
            line.position    = CGPoint(x: x, y: groundY + 10 + CGFloat(li) * 28)
            line.zPosition   = 5
            addChild(line)
        }

        // Pyramid
        let pyramid = CGMutablePath()
        pyramid.move(to: CGPoint(x: -80, y: 0))
        pyramid.addLine(to: CGPoint(x: 80, y: 0))
        pyramid.addLine(to: CGPoint(x: 0, y: 110))
        pyramid.closeSubpath()
        let pyrNode = SKShapeNode(path: pyramid)
        pyrNode.fillColor   = UIColor(hex: "#3a2c14")
        pyrNode.strokeColor = UIColor(hex: "#f5c842").withAlphaComponent(0.5)
        pyrNode.lineWidth   = 2
        pyrNode.position    = CGPoint(x: x, y: groundY + 130)
        pyrNode.zPosition   = 4
        addChild(pyrNode)

        // Gold apex glow (animated)
        for (r, a): (CGFloat, CGFloat) in [(32, 0.15), (20, 0.25), (10, 0.5)] {
            let ring = SKShapeNode(circleOfRadius: r)
            ring.fillColor   = UIColor(hex: "#f5c842").withAlphaComponent(a)
            ring.strokeColor = .clear
            ring.position    = CGPoint(x: x, y: groundY + 242)
            ring.zPosition   = 6
            let pulse = SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.35, duration: 1.0),
                SKAction.scale(to: 1.0,  duration: 1.0),
            ]))
            ring.run(pulse)
            addChild(ring)
        }

        // Doorway
        let door = SKShapeNode(rectOf: CGSize(width: 32, height: 55), cornerRadius: 4)
        door.fillColor   = UIColor(hex: "#08100a")
        door.strokeColor = UIColor(hex: "#f5c842").withAlphaComponent(0.4)
        door.lineWidth   = 1
        door.position    = CGPoint(x: x, y: groundY + 28)
        door.zPosition   = 5
        addChild(door)

        // Door inner glow
        let doorGlow = SKShapeNode(rectOf: CGSize(width: 24, height: 48), cornerRadius: 3)
        doorGlow.fillColor   = UIColor(hex: "#f5c842").withAlphaComponent(0.06)
        doorGlow.strokeColor = .clear
        doorGlow.position    = CGPoint(x: x, y: groundY + 28)
        doorGlow.zPosition   = 5
        let doorPulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.02, duration: 1.2),
            SKAction.fadeAlpha(to: 0.1,  duration: 1.2),
        ]))
        doorGlow.run(doorPulse)
        addChild(doorGlow)

        // Level-end trigger
        let trigger    = SKNode()
        let trigBody   = SKPhysicsBody(rectangleOf: CGSize(width: 50, height: 220))
        trigBody.isDynamic           = false
        trigBody.categoryBitMask     = Cat.levelEnd
        trigBody.contactTestBitMask  = Cat.player
        trigBody.collisionBitMask    = 0
        trigger.physicsBody  = trigBody
        trigger.position     = CGPoint(x: x, y: groundY + 110)
        addChild(trigger)
    }

    // MARK: - Player / Camera / HUD / Controls

    private func setupPlayer() {
        player          = PlayerNode()
        player.position = CGPoint(x: 80, y: tileSize * 5 + 24)
        player.zPosition = 10
        addChild(player)
    }

    private func setupCamera() {
        cam          = SKCameraNode()
        camera       = cam
        cam.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(cam)
    }

    private func setupHUD() {
        hud          = HUDNode(viewSize: size)
        hud.zPosition = 50
        cam.addChild(hud)
    }

    private func setupControls() {
        controls = ControlsNode(viewSize: size)
        controls.zPosition = 60

        controls.onLeft         = { [weak self] in self?.isMovingLeft  = true  }
        controls.onLeftRelease  = { [weak self] in self?.isMovingLeft  = false }
        controls.onRight        = { [weak self] in self?.isMovingRight = true  }
        controls.onRightRelease = { [weak self] in self?.isMovingRight = false }
        controls.onJump         = { [weak self] in self?.player.jump()         }

        cam.addChild(controls)
    }

    private func setupTutorialIfNeeded() {
        let shown = UserDefaults.standard.bool(forKey: "rey_tutorial_shown")
        guard !shown else { return }

        tutorial = TutorialNode(viewSize: size)
        tutorial!.zPosition = 80
        tutorial!.onComplete = { [weak self] in
            self?.tutorial = nil
            UserDefaults.standard.set(true, forKey: "rey_tutorial_shown")
        }
        cam.addChild(tutorial!)
    }

    // MARK: - Update loop

    override func update(_ currentTime: TimeInterval) {
        guard !levelDone else { return }

        if isMovingLeft       { player.moveLeft()       }
        else if isMovingRight { player.moveRight()      }
        else                  { player.stopHorizontal() }

        if let vy = player.physicsBody?.velocity.dy, vy < -1200 {
            player.physicsBody?.velocity.dy = -1200
        }

        // Camera lerp
        let halfW = size.width  / 2
        let halfH = size.height / 2
        let tx = max(halfW, min(player.position.x, worldWidth - halfW))
        cam.position.x += (tx - cam.position.x) * 0.12
        cam.position.y  = halfH

        for e in enemies { e.patrol() }

        if player.position.y < -80 { respawnPlayer() }
    }

    // MARK: - Touch (clue examination — controls handle their own touches)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Tutorial advance
        if tutorial != nil {
            tutorial?.advance()
            return
        }

        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        for node in nodes(at: loc) {
            if let clueNode = node as? ClueNode {
                clueNode.examine()
                onClueFound?(clueNode.clue)
                showCluePopup(clue: clueNode.clue)
                return
            }
        }
    }

    // MARK: - Contacts

    func didBegin(_ contact: SKPhysicsContact) {
        let (a, b) = sorted(contact)
        switch (a.categoryBitMask, b.categoryBitMask) {
        case (Cat.player, Cat.ground):
            player.setGrounded(true)
        case (Cat.player, Cat.collectible):
            if let n = b.node as? CollectibleNode { handleCollectible(n) }
        case (Cat.player, Cat.enemy):
            handleEnemyContact()
        case (Cat.player, Cat.clue):
            if let n = b.node as? ClueNode { handleClue(n) }
        case (Cat.player, Cat.levelEnd):
            handleLevelEnd()
        default: break
        }
    }

    func didEnd(_ contact: SKPhysicsContact) {
        let (a, b) = sorted(contact)
        if a.categoryBitMask == Cat.player && b.categoryBitMask == Cat.ground {
            let onGround = player.physicsBody?
                .allContactedBodies()
                .contains { $0.categoryBitMask == Cat.ground } ?? false
            if !onGround { player.setGrounded(false) }
        }
    }

    private func sorted(_ c: SKPhysicsContact) -> (SKPhysicsBody, SKPhysicsBody) {
        c.bodyA.categoryBitMask <= c.bodyB.categoryBitMask
            ? (c.bodyA, c.bodyB) : (c.bodyB, c.bodyA)
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
        invincible = true; tookDamage = true
        player.playHitEffect()
        hud.loseLife()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            self?.invincible = false
        }
    }

    private func handleClue(_ node: ClueNode) {
        node.examine()
        onClueFound?(node.clue)
        showCluePopup(clue: node.clue)
    }

    private func handleLevelEnd() {
        guard !levelDone else { return }
        levelDone = true
        isPaused  = true
        let elapsed = Date().timeIntervalSince1970 - levelStartTime
        onLevelComplete?(elapsed, !tookDamage)
        showVictoryBanner()
    }

    // MARK: - UI popups

    private func showCluePopup(clue: Clue) {
        let panel = SKShapeNode(rectOf: CGSize(width: 290, height: 165), cornerRadius: 14)
        panel.fillColor   = UIColor(hex: "#0a1620").withAlphaComponent(0.96)
        panel.strokeColor = UIColor(hex: "#9b59b6")
        panel.lineWidth   = 2
        panel.position    = CGPoint(x: 0, y: 50)
        panel.zPosition   = 82
        cam.addChild(panel)

        func label(_ text: String, size: CGFloat, color: UIColor, y: CGFloat) {
            let l = SKLabelNode(text: text)
            l.fontName = "Courier-Bold"; l.fontSize = size; l.fontColor = color
            l.verticalAlignmentMode = .center; l.horizontalAlignmentMode = .center
            l.position = CGPoint(x: 0, y: y); panel.addChild(l)
        }

        let sym = SKLabelNode(text: clue.symbol)
        sym.fontSize = 30; sym.verticalAlignmentMode = .center
        sym.position = CGPoint(x: 0, y: 55); panel.addChild(sym)

        label(clue.title,       size: 14, color: UIColor(hex: "#f5c842"), y:  26)
        let desc = SKLabelNode(text: clue.description)
        desc.fontName = "Courier"; desc.fontSize = 10
        desc.fontColor = UIColor.white.withAlphaComponent(0.78)
        desc.numberOfLines = 3; desc.preferredMaxLayoutWidth = 260
        desc.verticalAlignmentMode = .center; desc.horizontalAlignmentMode = .center
        desc.position = CGPoint(x: 0, y: -6); panel.addChild(desc)
        label("📓 Added to journal", size: 9, color: UIColor(hex: "#9b59b6"), y: -62)

        panel.run(SKAction.sequence([
            SKAction.wait(forDuration: 3.8),
            SKAction.fadeOut(withDuration: 0.4),
            SKAction.removeFromParent(),
        ]))
    }

    private func showVictoryBanner() {
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        overlay.fillColor = UIColor(hex: "#0a1620").withAlphaComponent(0)
        overlay.strokeColor = .clear; overlay.zPosition = 90
        cam.addChild(overlay)
        overlay.run(SKAction.fadeAlpha(to: 0.65, duration: 0.5))

        let trophy = SKLabelNode(text: "🏆")
        trophy.fontSize = 58; trophy.verticalAlignmentMode = .center
        trophy.position = CGPoint(x: 0, y: 55); trophy.zPosition = 91
        cam.addChild(trophy); trophy.setScale(0)
        trophy.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            SKAction.scale(to: 1.2, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.15),
        ]))

        let title = SKLabelNode(text: "LEVEL COMPLETE!")
        title.fontName = "Courier-Bold"; title.fontSize = 26
        title.fontColor = UIColor(hex: "#f5c842")
        title.verticalAlignmentMode = .center; title.position = CGPoint(x: 0, y: -18)
        title.zPosition = 91; cam.addChild(title)

        let sub = SKLabelNode(text: !tookDamage ? "🛡️ NO DAMAGE!" : "Keep exploring!")
        sub.fontName = "Courier"; sub.fontSize = 14
        sub.fontColor = UIColor.white.withAlphaComponent(0.75)
        sub.verticalAlignmentMode = .center; sub.position = CGPoint(x: 0, y: -55)
        sub.zPosition = 91; cam.addChild(sub)
    }

    // MARK: - Respawn

    private func respawnPlayer() {
        player.position = CGPoint(x: 80, y: tileSize * 5 + 24)
        player.physicsBody?.velocity = .zero
        if !invincible {
            invincible = true; tookDamage = true
            hud.loseLife()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.invincible = false
            }
        }
    }

    // MARK: - Torch

    private func addTorch(at position: CGPoint) {
        let stick = SKShapeNode(rectOf: CGSize(width: 6, height: 26), cornerRadius: 2)
        stick.fillColor = UIColor(hex: "#4a2c10"); stick.strokeColor = .clear
        stick.position = position; stick.zPosition = 4; addChild(stick)

        for (r, a, offset): (CGFloat, CGFloat, CGPoint) in [
            (22, 0.15, .zero), (14, 0.25, .zero), (7, 0.55, .zero)
        ] {
            let g = SKShapeNode(circleOfRadius: r)
            g.fillColor = UIColor(hex: "#ff6b20").withAlphaComponent(a)
            g.strokeColor = .clear
            g.position = CGPoint(x: position.x + offset.x, y: position.y + 22 + offset.y)
            g.zPosition = 5; addChild(g)
        }

        let flame = SKShapeNode(ellipseOf: CGSize(width: 10, height: 14))
        flame.fillColor = UIColor(hex: "#ff8030"); flame.strokeColor = .clear
        flame.position = CGPoint(x: position.x, y: position.y + 22); flame.zPosition = 6
        let flicker = SKAction.repeatForever(SKAction.sequence([
            SKAction.scaleX(to: 1.12, y: 0.88, duration: 0.1),
            SKAction.scaleX(to: 0.9,  y: 1.15, duration: 0.12),
            SKAction.scaleX(to: 1.0,  y: 1.0,  duration: 0.08),
        ]))
        flame.run(flicker); addChild(flame)
    }
}
