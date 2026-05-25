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

    // MARK: - Config
    let characterType: CharacterType

    // MARK: - Nodes
    private var player:   PlayerNode!
    private var cam:      SKCameraNode!
    private var hud:      HUDNode!
    private var controls: ControlsNode!
    private var tutorial: TutorialNode?
    private var enemies:  [EnemyNode] = []

    // MARK: - Control touch tracking (scene-level, reliable)
    private var leftControlTouch:  UITouch?
    private var rightControlTouch: UITouch?
    private var leftBtnRegion  = CGRect.zero
    private var rightBtnRegion = CGRect.zero
    private var jumpBtnRegion  = CGRect.zero

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

    // MARK: - Init
    init(size: CGSize, characterType: CharacterType = .male) {
        self.characterType = characterType
        super.init(size: size)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup
    override func didMove(to view: SKView) {
        backgroundColor = UIColor(hex: "#080414")
        setupPhysics()
        buildBackground()
        buildLevel()
        setupPlayer()
        setupCamera()
        setupHUD()
        setupControls()
        setupControlRegions()
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

    // MARK: - Control regions (in camera-local space)
    private func setupControlRegions() {
        let bottomY = -size.height / 2 + 56
        let lx      = -size.width  / 2 + 52
        let pad: CGFloat = 18
        leftBtnRegion  = CGRect(x: lx      - 29 - pad, y: bottomY - 29 - pad, width: 58 + pad*2, height: 58 + pad*2)
        rightBtnRegion = CGRect(x: lx + 70 - 29 - pad, y: bottomY - 29 - pad, width: 58 + pad*2, height: 58 + pad*2)
        jumpBtnRegion  = CGRect(x: size.width/2 - 60 - 33 - pad, y: bottomY - 33 - pad, width: 66 + pad*2, height: 66 + pad*2)
    }

    private func camRelative(_ touch: UITouch) -> CGPoint {
        let p = touch.location(in: self)
        return CGPoint(x: p.x - cam.position.x, y: p.y - cam.position.y)
    }

    // MARK: - Royal Background

    private func buildBackground() {
        drawRoyalSky()
        addWarmStars()
        addGoldenMoon()
        addDistantCityline()
        addRollingHills()
        addRoyalJungle()
    }

    private func drawRoyalSky() {
        // Warm royal gradient: deep night purple → amber horizon
        let bands: [(String, CGFloat)] = [
            ("#080414", 0.0), ("#120830", 0.18), ("#280a3a", 0.36),
            ("#3a1228", 0.52), ("#5a2010", 0.68), ("#7a3a06", 0.82),
            ("#9a5210", 0.92),
        ]
        for (i, (hex, frac)) in bands.enumerated() {
            let nextFrac = i + 1 < bands.count ? bands[i + 1].1 : 1.0
            let h = size.height * CGFloat(nextFrac - frac) + 2
            let strip = SKSpriteNode(color: UIColor(hex: hex),
                                     size: CGSize(width: worldWidth + 200, height: h))
            strip.anchorPoint = .zero
            strip.position    = CGPoint(x: -100, y: size.height * frac)
            strip.zPosition   = -22
            addChild(strip)
        }
        // Horizon glow
        let glow = SKSpriteNode(color: UIColor(hex: "#f5c842").withAlphaComponent(0.12),
                                size: CGSize(width: worldWidth + 200, height: 80))
        glow.anchorPoint = .zero
        glow.position    = CGPoint(x: -100, y: size.height * 0.84)
        glow.zPosition   = -21
        addChild(glow)
    }

    private func addWarmStars() {
        for _ in 0..<220 {
            let r = CGFloat.random(in: 0.4...2.8)
            let star = SKShapeNode(circleOfRadius: r)
            // Warm golden-white stars
            let warm = Bool.random()
            star.fillColor   = warm ? UIColor(hex: "#fff0c0") : UIColor.white
            star.strokeColor = .clear
            star.position    = CGPoint(
                x: CGFloat.random(in: 0...worldWidth),
                y: CGFloat.random(in: size.height * 0.42...size.height * 1.02)
            )
            star.alpha     = CGFloat.random(in: 0.15...0.95)
            star.zPosition = -21
            addChild(star)

            if Bool.random() {
                let twinkle = SKAction.repeatForever(SKAction.sequence([
                    SKAction.fadeAlpha(to: CGFloat.random(in: 0.05...0.2), duration: Double.random(in: 0.8...3.0)),
                    SKAction.fadeAlpha(to: CGFloat.random(in: 0.7...1.0),  duration: Double.random(in: 0.8...3.0)),
                ]))
                star.run(twinkle)
            }
        }
    }

    private func addGoldenMoon() {
        let cx = worldWidth * 0.15
        let cy = size.height * 0.84

        // Warm halos
        for (radius, alpha): (CGFloat, CGFloat) in [(100, 0.04), (72, 0.08), (52, 0.16), (36, 0.28)] {
            let halo = SKShapeNode(circleOfRadius: radius)
            halo.fillColor   = UIColor(hex: "#ffcc60").withAlphaComponent(alpha)
            halo.strokeColor = .clear
            halo.position    = CGPoint(x: cx, y: cy)
            halo.zPosition   = -20
            addChild(halo)
        }
        // Moon disc — warm golden white
        let moon = SKShapeNode(circleOfRadius: 32)
        moon.fillColor   = UIColor(hex: "#fff0c0")
        moon.strokeColor = UIColor(hex: "#f5c842").withAlphaComponent(0.5)
        moon.lineWidth   = 1.5
        moon.position    = CGPoint(x: cx, y: cy)
        moon.zPosition   = -19
        addChild(moon)
        // Craters
        for (ox, oy, r): (CGFloat, CGFloat, CGFloat) in [(-9, 7, 5), (11, -5, 4), (-2, -12, 3)] {
            let cr = SKShapeNode(circleOfRadius: r)
            cr.fillColor   = UIColor(hex: "#e8d8a0")
            cr.strokeColor = .clear
            cr.position    = CGPoint(x: cx + ox, y: cy + oy)
            cr.zPosition   = -18
            addChild(cr)
        }
    }

    private func addDistantCityline() {
        // Golden city silhouette in the sky
        let baseY = size.height * 0.56
        let path  = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: baseY))

        // Mayan city with stepped pyramids
        let buildings: [(CGFloat, CGFloat, Bool)] = [
            (200, 18, false), (320, 32, true), (480, 20, false), (580, 44, true),
            (720, 22, false), (880, 36, true), (1020, 18, false), (1160, 50, true),
            (1300, 24, false), (1440, 40, true), (1600, 16, false), (1740, 34, true),
            (1900, 20, false), (2060, 46, true), (2200, 22, false), (2360, 38, true),
            (2520, 18, false), (2680, 42, true), (2840, 24, false), (3000, 30, false),
            (3200, 0, false),
        ]
        var prevX: CGFloat = 0
        var prevY: CGFloat = baseY
        for (bx, rise, isPyramid) in buildings {
            if isPyramid {
                // Stepped pyramid shape
                let topY = baseY + rise
                let midY = baseY + rise * 0.55
                path.addLine(to: CGPoint(x: bx - 28, y: prevY))
                path.addLine(to: CGPoint(x: bx - 22, y: midY))
                path.addLine(to: CGPoint(x: bx - 14, y: midY))
                path.addLine(to: CGPoint(x: bx - 8,  y: topY))
                path.addLine(to: CGPoint(x: bx + 8,  y: topY))
                path.addLine(to: CGPoint(x: bx + 14, y: midY))
                path.addLine(to: CGPoint(x: bx + 22, y: midY))
                path.addLine(to: CGPoint(x: bx + 28, y: prevY))
            } else {
                path.addCurve(
                    to: CGPoint(x: bx, y: baseY + rise),
                    control1: CGPoint(x: prevX + 60, y: prevY),
                    control2: CGPoint(x: bx - 60, y: baseY + rise)
                )
            }
            prevX = bx; prevY = baseY + rise
        }
        path.addLine(to: CGPoint(x: 3200, y: 0))
        path.closeSubpath()

        let city = SKShapeNode(path: path)
        city.fillColor   = UIColor(hex: "#1a0c08").withAlphaComponent(0.85)
        city.strokeColor = UIColor(hex: "#f5c842").withAlphaComponent(0.12)
        city.lineWidth   = 0.5
        city.zPosition   = -17
        addChild(city)

        // Gold accent dots on pyramid tips
        for (bx, rise, isPyramid) in buildings where isPyramid && rise > 30 {
            let dot = SKShapeNode(circleOfRadius: 3)
            dot.fillColor   = UIColor(hex: "#f5c842")
            dot.strokeColor = .clear
            dot.position    = CGPoint(x: bx, y: baseY + rise + 4)
            dot.zPosition   = -16
            let pulse = SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: Double.random(in: 1...2.5)),
                SKAction.fadeAlpha(to: 1.0, duration: Double.random(in: 1...2.5)),
            ]))
            dot.run(pulse)
            addChild(dot)
        }
    }

    private func addRollingHills() {
        // Dark royal purple silhouette hills
        let path  = CGMutablePath()
        let baseY = size.height * 0.48
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: baseY))

        let peaks: [(CGFloat, CGFloat)] = [
            (180, 42), (420, 78), (680, 50), (940, 88),
            (1200, 58), (1480, 82), (1760, 46), (2040, 92),
            (2320, 62), (2600, 76), (2880, 50), (3200, 0),
        ]
        var prev: (CGFloat, CGFloat) = (0, baseY)
        for (x, rise) in peaks {
            path.addCurve(
                to: CGPoint(x: x, y: baseY + rise),
                control1: CGPoint(x: prev.0 + 90, y: prev.1),
                control2: CGPoint(x: x - 90, y: baseY + rise)
            )
            prev = (x, rise)
        }
        path.addLine(to: CGPoint(x: 3200, y: 0))
        path.closeSubpath()

        let hills = SKShapeNode(path: path)
        hills.fillColor   = UIColor(hex: "#0c0818")
        hills.strokeColor = .clear
        hills.zPosition   = -15
        addChild(hills)
    }

    private func addRoyalJungle() {
        // 4 depth layers, progressively more colourful towards foreground
        let layers: [(count: Int, dark: String, mid: String, light: String, minH: CGFloat, maxH: CGFloat, z: CGFloat)] = [
            (36, "#060d06", "#0a160a", "#0a160a",  45,  85, -13),
            (28, "#0a1a08", "#121e10", "#121e10",  60, 110, -11),
            (22, "#102010", "#1a3018", "#1a3018",  80, 145,  -9),
            (16, "#162a10", "#225020", "#2a6a28", 100, 180,  -7),
        ]
        let groundY = tileSize * 4 + tileSize / 2
        for layer in layers {
            let spacing = worldWidth / CGFloat(layer.count)
            for i in 0..<layer.count {
                let h = CGFloat.random(in: layer.minH...layer.maxH)
                let node = makeRoyalTree(
                    height: h,
                    dark:  UIColor(hex: layer.dark),
                    mid:   UIColor(hex: layer.mid),
                    light: UIColor(hex: layer.light)
                )
                node.position  = CGPoint(
                    x: CGFloat(i) * spacing + CGFloat.random(in: -20...20),
                    y: groundY
                )
                node.zPosition = layer.z
                addChild(node)
            }
        }
    }

    // MARK: - Level
    private func buildLevel() {
        let ts   = tileSize
        let cols = Int(worldWidth / ts)
        var heights = [Int](repeating: 4, count: cols)

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

    // MARK: - Royal stone tile
    private func makeTile(isTop: Bool, isGround: Bool) -> SKSpriteNode {
        let ts = tileSize
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: ts, height: ts))
        let img = renderer.image { ctx in
            let c = ctx.cgContext
            if isTop {
                // Warm stone body
                gradV(c, from: UIColor(hex: "#c4882c"), to: UIColor(hex: "#7a5018"),
                      rect: CGRect(x: 0, y: 0, width: ts, height: ts - 10))
                // Grass / moss strip
                gradV(c, from: UIColor(hex: "#4a8818"), to: UIColor(hex: "#6ab030"),
                      rect: CGRect(x: 0, y: ts - 10, width: ts, height: 10))
                if isGround {
                    // Grass blades
                    c.setFillColor(UIColor(hex: "#88d040").cgColor)
                    for xi in stride(from: 2.0, through: ts - 4, by: 6.0) {
                        let blade = CGMutablePath()
                        blade.move(to:  CGPoint(x: xi, y: ts - 7))
                        blade.addQuadCurve(to: CGPoint(x: xi + 2, y: ts + 1),
                                           control: CGPoint(x: xi - 1, y: ts - 1))
                        blade.addQuadCurve(to: CGPoint(x: xi + 5, y: ts - 7),
                                           control: CGPoint(x: xi + 6, y: ts - 1))
                        c.addPath(blade); c.fillPath()
                    }
                } else {
                    c.setFillColor(UIColor(hex: "#5a8830").withAlphaComponent(0.6).cgColor)
                    for xi in stride(from: 2.0, through: ts - 6, by: 9.0) {
                        c.fillEllipse(in: CGRect(x: xi, y: ts - 9, width: 6, height: 4))
                    }
                }
                // Stone line detail
                c.setStrokeColor(UIColor(hex: "#f5c842").withAlphaComponent(0.06).cgColor)
                c.setLineWidth(1)
                c.move(to: CGPoint(x: 0, y: ts * 0.45)); c.addLine(to: CGPoint(x: ts, y: ts * 0.45))
                c.strokePath()
            } else {
                // Sandstone dirt
                gradV(c, from: UIColor(hex: "#5a3010"), to: UIColor(hex: "#8a5828"),
                      rect: CGRect(x: 0, y: 0, width: ts, height: ts))
                // Carved vein
                c.setStrokeColor(UIColor(hex: "#3a1a08").withAlphaComponent(0.4).cgColor)
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
        body.isDynamic          = false
        body.categoryBitMask    = Cat.ground
        body.collisionBitMask   = Cat.player | Cat.enemy
        body.contactTestBitMask = Cat.player
        body.friction           = 0.3
        node.physicsBody        = body
        node.zPosition          = 0
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

    // MARK: - Royal lush tree (multi-oval with gold highlights)
    private func makeRoyalTree(height h: CGFloat, dark: UIColor, mid: UIColor, light: UIColor) -> SKNode {
        let tree   = SKNode()
        let trunkH = h * 0.4
        let trunkW = h * 0.12
        let cH     = h - trunkH
        let canopyY = trunkH + cH * 0.12

        let trunk = SKShapeNode(rectOf: CGSize(width: trunkW, height: trunkH), cornerRadius: trunkW / 2.5)
        trunk.fillColor   = UIColor(hex: "#3a1a06").withAlphaComponent(0.9)
        trunk.strokeColor = .clear
        trunk.position    = CGPoint(x: 0, y: trunkH / 2)
        tree.addChild(trunk)

        let ovals: [(CGFloat, CGFloat, CGFloat, CGFloat, UIColor)] = [
            (0,         canopyY,          cH*0.88, cH*0.60, dark),
            (0,         canopyY + cH*0.1, cH*0.72, cH*0.52, mid),
            (-cH*0.28,  canopyY - cH*0.04, cH*0.52, cH*0.40, mid),
            ( cH*0.26,  canopyY - cH*0.02, cH*0.48, cH*0.38, mid),
            ( cH*0.06,  canopyY + cH*0.22, cH*0.50, cH*0.38, light),
            (-cH*0.08,  canopyY + cH*0.30, cH*0.32, cH*0.28, light),
        ]
        for (ox, oy, w, hh, color) in ovals {
            let oval = SKShapeNode(ellipseOf: CGSize(width: w, height: hh))
            oval.fillColor   = color
            oval.strokeColor = .clear
            oval.position    = CGPoint(x: ox, y: oy)
            tree.addChild(oval)
        }

        // Gold canopy highlight on foreground trees (brighter layers)
        if light.cgColor.alpha > 0.5 {
            let highlight = SKShapeNode(ellipseOf: CGSize(width: cH * 0.22, height: cH * 0.14))
            highlight.fillColor   = UIColor(hex: "#f5c842").withAlphaComponent(0.08)
            highlight.strokeColor = .clear
            highlight.position    = CGPoint(x: cH * 0.05, y: canopyY + cH * 0.25)
            tree.addChild(highlight)
        }
        return tree
    }

    // MARK: - Decorations
    private func placeDecoration() {
        let ts      = tileSize
        let groundY = ts * 4 + ts / 2 + 14

        let fgColors: [(String, String, String)] = [
            ("#1a5c14", "#28802a", "#4ab040"),
            ("#155018", "#228030", "#38a838"),
            ("#1c5c10", "#2a8025", "#48b035"),
        ]
        let treeSpots: [(CGFloat, CGFloat)] = [
            (140, 90), (420, 110), (820, 130), (1240, 100),
            (1680, 120), (2080, 105), (2580, 125), (3000, 90),
        ]
        for (i, (x, h)) in treeSpots.enumerated() {
            let c = fgColors[i % fgColors.count]
            let tree = makeRoyalTree(height: h, dark: UIColor(hex: c.0),
                                     mid: UIColor(hex: c.1), light: UIColor(hex: c.2))
            tree.position  = CGPoint(x: x, y: groundY)
            tree.zPosition = 2
            addChild(tree)
        }

        let bushX: [CGFloat] = [90, 310, 550, 760, 1060, 1360, 1600, 1950, 2300, 2700]
        for x in bushX {
            let w = CGFloat.random(in: 28...50)
            let bush = SKShapeNode(ellipseOf: CGSize(width: w, height: w * 0.55))
            bush.fillColor   = UIColor(hex: "#246020")
            bush.strokeColor = .clear
            bush.position    = CGPoint(x: x, y: groundY - 4)
            bush.zPosition   = 1
            addChild(bush)
        }

        // Royal torches at clue locations
        for x: CGFloat in [490, 1820, 800, 1400, 2200] {
            addTorch(at: CGPoint(x: x, y: groundY + 26))
        }

        // Royal banners on tall poles
        for x: CGFloat in [300, 900, 1500, 2100, 2700] {
            addRoyalBanner(at: CGPoint(x: x, y: groundY))
        }
    }

    private func addRoyalBanner(at pos: CGPoint) {
        // Pole
        let pole = SKShapeNode(rectOf: CGSize(width: 3, height: 60), cornerRadius: 1)
        pole.fillColor   = UIColor(hex: "#8a6030")
        pole.strokeColor = .clear
        pole.position    = CGPoint(x: pos.x, y: pos.y + 30)
        pole.zPosition   = 3
        addChild(pole)
        // Banner flag
        let flag = SKShapeNode(rectOf: CGSize(width: 18, height: 22), cornerRadius: 2)
        flag.fillColor   = UIColor(hex: "#6a1010")
        flag.strokeColor = UIColor(hex: "#f5c842").withAlphaComponent(0.6)
        flag.lineWidth   = 1
        flag.position    = CGPoint(x: pos.x + 10, y: pos.y + 52)
        flag.zPosition   = 3
        let wave = SKAction.repeatForever(SKAction.sequence([
            SKAction.scaleX(to: 1.05, y: 1.0, duration: 0.6),
            SKAction.scaleX(to: 0.95, y: 1.0, duration: 0.6),
        ]))
        flag.run(wave)
        addChild(flag)
        // Gold symbol on flag
        let sym = SKLabelNode(text: "♔")
        sym.fontSize   = 10
        sym.verticalAlignmentMode   = .center
        sym.horizontalAlignmentMode = .center
        sym.fontColor  = UIColor(hex: "#f5c842")
        sym.position   = CGPoint(x: pos.x + 10, y: pos.y + 52)
        sym.zPosition  = 4
        addChild(sym)
    }

    private func addFireflies() {
        for _ in 0..<50 {
            let ff   = SKNode()
            let glow = SKShapeNode(circleOfRadius: 5)
            glow.fillColor   = UIColor(hex: "#f0d060").withAlphaComponent(0.3)
            glow.strokeColor = .clear
            let core = SKShapeNode(circleOfRadius: 1.8)
            core.fillColor   = UIColor(hex: "#fff0a0")
            core.strokeColor = .clear
            glow.addChild(core)
            ff.addChild(glow)
            ff.position  = CGPoint(
                x: CGFloat.random(in: 60...worldWidth - 60),
                y: CGFloat.random(in: tileSize * 3.5...tileSize * 10)
            )
            ff.zPosition = 6
            addChild(ff)

            let dur = Double.random(in: 2.5...6.5)
            let dx  = CGFloat.random(in: -55...55)
            let dy  = CGFloat.random(in: -22...22)
            ff.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.moveBy(x: dx, y: dy, duration: dur),
                SKAction.moveBy(x: -dx, y: -dy, duration: dur),
            ])))
            glow.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.wait(forDuration: Double.random(in: 0...2.5)),
                SKAction.fadeAlpha(to: 0.04, duration: Double.random(in: 0.4...1.2)),
                SKAction.fadeAlpha(to: 0.9,  duration: Double.random(in: 0.4...1.2)),
            ])))
        }
    }

    private func addGroundMist() {
        for i in 0..<14 {
            let w    = CGFloat.random(in: 300...580)
            let mist = SKSpriteNode(
                color: UIColor(hex: "#f0c880").withAlphaComponent(0.035),
                size: CGSize(width: w, height: 28)
            )
            mist.anchorPoint = CGPoint(x: 0, y: 0.5)
            mist.position    = CGPoint(
                x: CGFloat(i) * 280 + CGFloat.random(in: -30...30),
                y: tileSize * 4 + CGFloat.random(in: 8...26)
            )
            mist.zPosition = 4
            mist.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.moveBy(x: CGFloat.random(in: 20...40), y: 0, duration: Double.random(in: 3...6)),
                SKAction.moveBy(x: -CGFloat.random(in: 20...40), y: 0, duration: Double.random(in: 3...6)),
            ])))
            mist.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.01, duration: Double.random(in: 2...4)),
                SKAction.fadeAlpha(to: 0.06, duration: Double.random(in: 2...4)),
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
            c.position = CGPoint(x: x, y: y); c.zPosition = 3
            addChild(c)
        }
        for pos: CGPoint in [
            CGPoint(x: 830,  y: ts*10+24),
            CGPoint(x: 1780, y: ts*5+24),
            CGPoint(x: 2900, y: ts*5+24),
        ] {
            let a = CollectibleNode(type: .artifact)
            a.position = pos; a.zPosition = 3
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
            n.position = pos; n.zPosition = 3
            addChild(n)
        }
    }

    // MARK: - Grand Royal Temple
    private func buildTemple(x: CGFloat) {
        let ts      = tileSize
        let groundY = ts * 4 + ts / 2

        // Vine curtains
        for vx: CGFloat in [-70, -42, 42, 70] {
            for seg in 0..<7 {
                let vine = SKShapeNode(circleOfRadius: 3)
                vine.fillColor = UIColor(hex: "#1e6014")
                vine.strokeColor = .clear
                vine.position    = CGPoint(x: x + vx, y: groundY + 18 + CGFloat(seg) * 22)
                vine.zPosition   = 3
                addChild(vine)
            }
        }

        // 3-tier stepped pyramid base
        let tiers: [(CGFloat, CGFloat, CGFloat)] = [
            (160, 50,  40),   // (width, height, yBase)
            (120, 50,  90),
            (80,  50, 140),
        ]
        for (tw, th, ty) in tiers {
            let tier = SKShapeNode(rectOf: CGSize(width: tw, height: th), cornerRadius: 4)
            tier.fillColor   = UIColor(hex: "#3a2c14")
            tier.strokeColor = UIColor(hex: "#f5c842").withAlphaComponent(0.45)
            tier.lineWidth   = 1.5
            tier.position    = CGPoint(x: x, y: groundY + ty + th/2)
            tier.zPosition   = 4
            addChild(tier)
            // Gold trim line on each tier
            let trim = SKShapeNode(rectOf: CGSize(width: tw - 4, height: 3))
            trim.fillColor   = UIColor(hex: "#f5c842").withAlphaComponent(0.35)
            trim.strokeColor = .clear
            trim.position    = CGPoint(x: x, y: groundY + ty + th - 2)
            trim.zPosition   = 5
            addChild(trim)
        }

        // Pyramid top
        let pyramid = CGMutablePath()
        pyramid.move(to:    CGPoint(x: -55, y: 0))
        pyramid.addLine(to: CGPoint(x:  55, y: 0))
        pyramid.addLine(to: CGPoint(x:   0, y: 90))
        pyramid.closeSubpath()
        let pyr = SKShapeNode(path: pyramid)
        pyr.fillColor   = UIColor(hex: "#3a2c14")
        pyr.strokeColor = UIColor(hex: "#f5c842").withAlphaComponent(0.45)
        pyr.lineWidth   = 1.5
        pyr.position    = CGPoint(x: x, y: groundY + 190)
        pyr.zPosition   = 4
        addChild(pyr)

        // Animated gold apex (3 rings)
        for (r, a): (CGFloat, CGFloat) in [(38, 0.14), (24, 0.26), (12, 0.55)] {
            let ring = SKShapeNode(circleOfRadius: r)
            ring.fillColor   = UIColor(hex: "#f5c842").withAlphaComponent(a)
            ring.strokeColor = .clear
            ring.position    = CGPoint(x: x, y: groundY + 282)
            ring.zPosition   = 6
            ring.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.4,  duration: 1.1),
                SKAction.scale(to: 1.0,  duration: 1.1),
            ])))
            addChild(ring)
        }

        // Doorway
        let door = SKShapeNode(rectOf: CGSize(width: 34, height: 58), cornerRadius: 5)
        door.fillColor   = UIColor(hex: "#080e0a")
        door.strokeColor = UIColor(hex: "#f5c842").withAlphaComponent(0.45)
        door.lineWidth   = 1.5
        door.position    = CGPoint(x: x, y: groundY + 29)
        door.zPosition   = 5
        addChild(door)
        let doorGlow = SKShapeNode(rectOf: CGSize(width: 26, height: 50), cornerRadius: 4)
        doorGlow.fillColor   = UIColor(hex: "#f5c842").withAlphaComponent(0.06)
        doorGlow.strokeColor = .clear
        doorGlow.position    = CGPoint(x: x, y: groundY + 29)
        doorGlow.zPosition   = 5
        doorGlow.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.02, duration: 1.3),
            SKAction.fadeAlpha(to: 0.12, duration: 1.3),
        ])))
        addChild(doorGlow)

        // Level-end trigger
        let trigger  = SKNode()
        let trigBody = SKPhysicsBody(rectangleOf: CGSize(width: 50, height: 260))
        trigBody.isDynamic          = false
        trigBody.categoryBitMask    = Cat.levelEnd
        trigBody.contactTestBitMask = Cat.player
        trigBody.collisionBitMask   = 0
        trigger.physicsBody = trigBody
        trigger.position    = CGPoint(x: x, y: groundY + 130)
        addChild(trigger)
    }

    // MARK: - Torch
    private func addTorch(at position: CGPoint) {
        let stick = SKShapeNode(rectOf: CGSize(width: 5, height: 28), cornerRadius: 2)
        stick.fillColor = UIColor(hex: "#6a3810"); stick.strokeColor = .clear
        stick.position = position; stick.zPosition = 4; addChild(stick)
        for (r, a): (CGFloat, CGFloat) in [(24, 0.14), (16, 0.26), (8, 0.55)] {
            let g = SKShapeNode(circleOfRadius: r)
            g.fillColor   = UIColor(hex: "#ff8020").withAlphaComponent(a)
            g.strokeColor = .clear
            g.position    = CGPoint(x: position.x, y: position.y + 24); g.zPosition = 5; addChild(g)
        }
        let flame = SKShapeNode(ellipseOf: CGSize(width: 10, height: 16))
        flame.fillColor   = UIColor(hex: "#ffaa30"); flame.strokeColor = .clear
        flame.position    = CGPoint(x: position.x, y: position.y + 24); flame.zPosition = 6
        flame.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scaleX(to: 1.12, y: 0.88, duration: 0.1),
            SKAction.scaleX(to: 0.9,  y: 1.15, duration: 0.12),
            SKAction.scaleX(to: 1.0,  y: 1.0,  duration: 0.08),
        ])))
        addChild(flame)
    }

    // MARK: - Player / Camera / HUD / Controls
    private func setupPlayer() {
        player          = PlayerNode(characterType: characterType)
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
        controls          = ControlsNode(viewSize: size)
        controls.zPosition = 60
        cam.addChild(controls)
    }

    private func setupTutorialIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: "rey_tutorial_shown") else { return }
        tutorial          = TutorialNode(viewSize: size)
        tutorial!.zPosition = 80
        tutorial!.onComplete = { [weak self] in
            self?.tutorial = nil
            UserDefaults.standard.set(true, forKey: "rey_tutorial_shown")
        }
        cam.addChild(tutorial!)
    }

    // MARK: - Update
    override func update(_ currentTime: TimeInterval) {
        guard !levelDone else { return }

        if isMovingLeft       { player.moveLeft()       }
        else if isMovingRight { player.moveRight()      }
        else                  { player.stopHorizontal() }

        if let vy = player.physicsBody?.velocity.dy, vy < -1200 {
            player.physicsBody?.velocity.dy = -1200
        }

        let halfW = size.width  / 2
        let halfH = size.height / 2
        let tx = max(halfW, min(player.position.x, worldWidth - halfW))
        cam.position.x += (tx - cam.position.x) * 0.12
        cam.position.y  = halfH

        for e in enemies { e.patrol() }
        if player.position.y < -80 { respawnPlayer() }
    }

    // MARK: - Touch (scene-level — reliable for camera children)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let cp = camRelative(touch)

            if leftBtnRegion.contains(cp), leftControlTouch == nil {
                leftControlTouch = touch
                isMovingLeft = true
                controls.highlight(.left, on: true)

            } else if rightBtnRegion.contains(cp), rightControlTouch == nil {
                rightControlTouch = touch
                isMovingRight = true
                controls.highlight(.right, on: true)

            } else if jumpBtnRegion.contains(cp) {
                player.jump()
                controls.highlight(.jump, on: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) { [weak self] in
                    self?.controls.highlight(.jump, on: false)
                }

            } else if tutorial != nil {
                tutorial?.advance()

            } else {
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
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if touch == leftControlTouch {
                leftControlTouch = nil
                isMovingLeft = false
                controls.highlight(.left, on: false)
            }
            if touch == rightControlTouch {
                rightControlTouch = nil
                isMovingRight = false
                controls.highlight(.right, on: false)
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
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
        levelDone = true; isPaused = true
        let elapsed = Date().timeIntervalSince1970 - levelStartTime
        onLevelComplete?(elapsed, !tookDamage)
        showVictoryBanner()
    }

    // MARK: - Popups
    private func showCluePopup(clue: Clue) {
        let panel = SKShapeNode(rectOf: CGSize(width: 290, height: 165), cornerRadius: 14)
        panel.fillColor   = UIColor(hex: "#0a1620").withAlphaComponent(0.96)
        panel.strokeColor = UIColor(hex: "#9b59b6")
        panel.lineWidth   = 2
        panel.position    = CGPoint(x: 0, y: 50)
        panel.zPosition   = 82
        cam.addChild(panel)

        let sym = SKLabelNode(text: clue.symbol)
        sym.fontSize = 30; sym.verticalAlignmentMode = .center
        sym.position = CGPoint(x: 0, y: 55); panel.addChild(sym)

        func lbl(_ text: String, sz: CGFloat, color: UIColor, y: CGFloat) {
            let l = SKLabelNode(text: text)
            l.fontName = "Courier-Bold"; l.fontSize = sz; l.fontColor = color
            l.verticalAlignmentMode = .center; l.horizontalAlignmentMode = .center
            l.position = CGPoint(x: 0, y: y); panel.addChild(l)
        }
        lbl(clue.title, sz: 14, color: UIColor(hex: "#f5c842"), y: 26)
        let desc = SKLabelNode(text: clue.description)
        desc.fontName = "Courier"; desc.fontSize = 10
        desc.fontColor = UIColor.white.withAlphaComponent(0.78)
        desc.numberOfLines = 3; desc.preferredMaxLayoutWidth = 260
        desc.verticalAlignmentMode = .center; desc.horizontalAlignmentMode = .center
        desc.position = CGPoint(x: 0, y: -6); panel.addChild(desc)
        lbl("📓 Added to journal", sz: 9, color: UIColor(hex: "#9b59b6"), y: -62)

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
}
