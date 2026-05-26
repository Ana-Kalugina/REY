import SpriteKit

class PlayerNode: SKNode {

    struct Cat {
        static let player:      UInt32 = 0x1 << 0
        static let ground:      UInt32 = 0x1 << 1
        static let collectible: UInt32 = 0x1 << 2
        static let enemy:       UInt32 = 0x1 << 3
        static let clue:        UInt32 = 0x1 << 4
        static let levelEnd:    UInt32 = 0x1 << 5
    }

    private let moveSpeed:  CGFloat = 300
    private let jumpForce:  CGFloat = 680
    private var isGrounded  = false
    private var facingRight = true
    private var body: SKSpriteNode!

    let characterType: CharacterType

    init(characterType: CharacterType = .male) {
        self.characterType = characterType
        super.init()
        buildSprite()
        setupPhysics()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Sprite 68 × 84 px  (horse + rider, side view facing RIGHT)
    // Drawing uses UIKit coords: y=0 = TOP of image (hat), y=83 = bottom (hooves).
    // UIGraphicsImageRenderer automatically applies the UIKit Y-flip so row-0 of the
    // resulting UIImage corresponds to the visual top.  SpriteKit maps UIImage row-0
    // to the sprite's top → hat appears at the top, hooves at the bottom. ✓
    private func buildSprite() {
        let sz = CGSize(width: 68, height: 84)
        let renderer = UIGraphicsImageRenderer(size: sz)
        let uiImg = renderer.image { ctx in
            drawHorse(ctx.cgContext, sz: sz)
            switch characterType {
            case .male:   drawRey(ctx.cgContext)
            case .female: drawReina(ctx.cgContext)
            }
        }
        body = SKSpriteNode(texture: SKTexture(image: uiImg), size: sz)
        body.anchorPoint = CGPoint(x: 0.5, y: 0)
        addChild(body)
    }

    // MARK: - Horse (shared, chestnut brown)
    private func drawHorse(_ c: CGContext, sz: CGSize) {
        func fill(_ r: CGRect, _ hex: String, radius: CGFloat = 0) {
            c.setFillColor(UIColor(hex: hex).cgColor)
            if radius > 0 {
                c.addPath(UIBezierPath(roundedRect: r, cornerRadius: radius).cgPath); c.fillPath()
            } else { c.fill(r) }
        }

        // ── Body ──
        fill(CGRect(x: 4,  y: 44, width: 55, height: 24), "#7a3a10", radius: 9)
        // Belly highlight
        c.setFillColor(UIColor(hex: "#9a5a28").withAlphaComponent(0.4).cgColor)
        c.fillEllipse(in: CGRect(x: 16, y: 50, width: 26, height: 12))

        // ── Neck ──
        let neck = CGMutablePath()
        neck.move(to: CGPoint(x: 46, y: 46))
        neck.addCurve(to:  CGPoint(x: 56, y: 26),
                     control1: CGPoint(x: 52, y: 44),
                     control2: CGPoint(x: 58, y: 34))
        neck.addLine(to: CGPoint(x: 63, y: 28))
        neck.addCurve(to:  CGPoint(x: 57, y: 48),
                     control1: CGPoint(x: 63, y: 38),
                     control2: CGPoint(x: 61, y: 46))
        neck.closeSubpath()
        c.setFillColor(UIColor(hex: "#7a3a10").cgColor)
        c.addPath(neck); c.fillPath()

        // ── Head ──
        fill(CGRect(x: 52, y: 22, width: 14, height: 20), "#7a3a10", radius: 4)
        // Snout
        fill(CGRect(x: 58, y: 28, width: 10, height: 12), "#8a4a18", radius: 3)
        // Eye
        c.setFillColor(UIColor.black.cgColor)
        c.fillEllipse(in: CGRect(x: 60, y: 25, width: 5, height: 5))
        c.setFillColor(UIColor.white.cgColor)
        c.fill(CGRect(x: 63, y: 25, width: 2, height: 2)) // highlight
        // Nostril
        c.setFillColor(UIColor(hex: "#4a1a08").cgColor)
        c.fillEllipse(in: CGRect(x: 63, y: 36, width: 3, height: 2))
        // Ear
        fill(CGRect(x: 56, y: 17, width: 6, height: 9), "#8a4a18", radius: 3)
        c.setFillColor(UIColor(hex: "#ffb0a0").cgColor)
        c.fillEllipse(in: CGRect(x: 57, y: 18, width: 3, height: 5))

        // ── Mane ──
        c.setFillColor(UIColor(hex: "#2a1008").cgColor)
        for (mx, my, mw, mh): (CGFloat,CGFloat,CGFloat,CGFloat) in
            [(46,20,10,6),(49,23,9,5),(52,26,8,5),(55,29,7,5)] {
            c.addPath(UIBezierPath(roundedRect: CGRect(x:mx,y:my,width:mw,height:mh), cornerRadius:3).cgPath)
            c.fillPath()
        }

        // ── Tail ──
        let tail = CGMutablePath()
        tail.move(to:       CGPoint(x:  8, y: 50))
        tail.addCurve(to:   CGPoint(x: -4, y: 70),
                     control1: CGPoint(x: -4, y: 52),
                     control2: CGPoint(x: -8, y: 64))
        c.setStrokeColor(UIColor(hex: "#2a1008").cgColor)
        c.setLineWidth(5); c.addPath(tail); c.strokePath()
        c.setLineWidth(2.5)
        c.setStrokeColor(UIColor(hex: "#4a2010").cgColor)
        let tail2 = CGMutablePath()
        tail2.move(to:     CGPoint(x: 10, y: 50))
        tail2.addCurve(to: CGPoint(x: -2, y: 74),
                      control1: CGPoint(x: -2, y: 56),
                      control2: CGPoint(x: -6, y: 68))
        c.addPath(tail2); c.strokePath()

        // ── Legs ──
        for lx: CGFloat in [10, 20, 37, 47] {
            fill(CGRect(x: lx, y: 62, width: 8, height: 20), "#5a2808")
            // Knee joint
            fill(CGRect(x: lx-1, y: 70, width: 10, height: 5), "#6a3010", radius: 2)
        }
        // Hooves
        for lx: CGFloat in [9, 19, 36, 46] {
            fill(CGRect(x: lx-1, y: 78, width: 11, height: 6), "#1a0806", radius: 3)
        }

        // ── Saddle ──
        fill(CGRect(x: 18, y: 38, width: 32, height: 12), "#6a1010", radius: 4)
        // Gold trim
        c.setStrokeColor(UIColor(hex: "#f5c842").withAlphaComponent(0.75).cgColor)
        c.setLineWidth(1.5)
        c.addPath(UIBezierPath(roundedRect: CGRect(x:18,y:38,width:32,height:12), cornerRadius:4).cgPath)
        c.strokePath()
        // Saddle front/back raised parts
        fill(CGRect(x: 16, y: 36, width: 8, height: 10), "#7a1818", radius: 3)
        fill(CGRect(x: 44, y: 36, width: 8, height: 10), "#7a1818", radius: 3)
        // Stirrups
        c.setStrokeColor(UIColor(hex: "#c8a030").cgColor); c.setLineWidth(2)
        c.move(to: CGPoint(x: 24, y: 50)); c.addLine(to: CGPoint(x: 20, y: 60))
        c.move(to: CGPoint(x: 46, y: 50)); c.addLine(to: CGPoint(x: 50, y: 60))
        c.strokePath()
        fill(CGRect(x: 16, y: 60, width: 8, height: 4), "#c8a030", radius: 2)
        fill(CGRect(x: 46, y: 60, width: 8, height: 4), "#c8a030", radius: 2)
    }

    // MARK: - REY  (inspired by bold adventurer archetype — red shirt, khaki vest, tan hat)
    // Sitting on saddle (y≈36), visible from hat top (y≈0) to waist (y≈38)
    private func drawRey(_ c: CGContext) {
        func fill(_ r: CGRect, _ hex: String, radius: CGFloat = 0) {
            c.setFillColor(UIColor(hex: hex).cgColor)
            if radius > 0 {
                c.addPath(UIBezierPath(roundedRect: r, cornerRadius: radius).cgPath); c.fillPath()
            } else { c.fill(r) }
        }

        // ── Legs (gripping horse) ──
        fill(CGRect(x: 16, y: 30, width: 10, height: 16), "#4a5c28", radius: 2) // left leg
        fill(CGRect(x: 36, y: 30, width: 10, height: 16), "#4a5c28", radius: 2) // right leg
        // Boots
        fill(CGRect(x: 14, y: 42, width: 12, height: 8), "#2a1008", radius: 3)
        fill(CGRect(x: 36, y: 42, width: 12, height: 8), "#2a1008", radius: 3)

        // ── RED shirt / torso ──
        fill(CGRect(x: 18, y: 18, width: 26, height: 18), "#c82020", radius: 3)
        // Shirt shadow sides
        fill(CGRect(x: 18, y: 18, width: 5, height: 18), "#8a1010", radius: 2)
        fill(CGRect(x: 39, y: 18, width: 5, height: 18), "#8a1010", radius: 2)
        // Shirt buttons line
        c.setStrokeColor(UIColor(hex: "#e84040").cgColor); c.setLineWidth(1)
        c.move(to: CGPoint(x: 31, y: 19)); c.addLine(to: CGPoint(x: 31, y: 35)); c.strokePath()

        // ── Khaki explorer VEST over shirt ──
        fill(CGRect(x: 17, y: 18, width: 6, height: 18), "#a07030", radius: 2) // left side vest
        fill(CGRect(x: 39, y: 18, width: 6, height: 18), "#a07030", radius: 2) // right side vest
        // Vest pockets
        fill(CGRect(x: 17, y: 22, width: 6, height: 5), "#8a5820", radius: 1)
        fill(CGRect(x: 39, y: 22, width: 6, height: 5), "#8a5820", radius: 1)

        // ── Belt ──
        fill(CGRect(x: 17, y: 34, width: 28, height: 4), "#5a2808")
        fill(CGRect(x: 28, y: 32, width: 8, height: 8), "#d4a020", radius: 1) // buckle

        // ── NECK scarf (green — distinctive colour) ──
        fill(CGRect(x: 25, y: 15, width: 12, height: 6), "#2a8040", radius: 2)

        // ── HAIR (dark brown) ──
        fill(CGRect(x: 22, y:  8, width: 20, height:  8), "#3a1a08", radius: 4)
        fill(CGRect(x: 20, y: 12, width:  5, height:  8), "#3a1a08", radius: 2)  // left
        fill(CGRect(x: 37, y: 12, width:  5, height:  6), "#3a1a08", radius: 2)  // right

        // ── HEAD (skin) ──
        fill(CGRect(x: 22, y: 8, width: 20, height: 14), "#d4906a", radius: 6)
        // Jaw shadow
        c.setFillColor(UIColor(hex: "#b87050").withAlphaComponent(0.3).cgColor)
        c.fillEllipse(in: CGRect(x: 24, y: 17, width: 16, height: 6))
        // Stubble (adventurer look)
        c.setFillColor(UIColor(hex: "#6a3a18").withAlphaComponent(0.25).cgColor)
        c.fillEllipse(in: CGRect(x: 25, y: 17, width: 12, height: 5))

        // ── EYES ──
        c.setFillColor(UIColor.white.cgColor)
        c.addPath(UIBezierPath(roundedRect: CGRect(x:24,y:10,width:5,height:5), cornerRadius:2).cgPath); c.fillPath()
        c.addPath(UIBezierPath(roundedRect: CGRect(x:32,y:10,width:5,height:5), cornerRadius:2).cgPath); c.fillPath()
        c.setFillColor(UIColor(hex: "#2a6020").cgColor)  // green eyes
        c.fillEllipse(in: CGRect(x:25,y:11,width:3,height:3))
        c.fillEllipse(in: CGRect(x:33,y:11,width:3,height:3))
        c.setFillColor(UIColor.black.cgColor)
        c.fillEllipse(in: CGRect(x:26,y:12,width:2,height:2))
        c.fillEllipse(in: CGRect(x:34,y:12,width:2,height:2))
        c.setFillColor(UIColor.white.cgColor)
        c.fill(CGRect(x:27,y:11,width:1,height:1))
        c.fill(CGRect(x:35,y:11,width:1,height:1))
        // Brow (determined look)
        c.setFillColor(UIColor(hex: "#3a1a08").cgColor)
        c.fill(CGRect(x:24,y: 9,width:5,height:2))
        c.fill(CGRect(x:32,y: 9,width:5,height:2))

        // ── HAT (tan/beige wide brim explorer hat) ──
        // Brim
        fill(CGRect(x: 16, y: 5, width: 32, height: 5), "#c8a050", radius: 2)
        // Crown
        fill(CGRect(x: 21, y: 0, width: 22, height: 9), "#c8a050", radius: 4)
        // Hat shadow
        fill(CGRect(x: 21, y: 0, width: 22, height: 3), "#a07030", radius: 2)
        // Hat band (red — matches shirt)
        fill(CGRect(x: 21, y: 5, width: 22, height: 3), "#c82020")
        // Highlight on brim
        c.setFillColor(UIColor(hex: "#e0c070").withAlphaComponent(0.5).cgColor)
        c.fillEllipse(in: CGRect(x:24, y:1, width:8, height:4))
    }

    // MARK: - REINA  (teal jacket, dark hair in braid, purple scarf — distinct from REY)
    private func drawReina(_ c: CGContext) {
        func fill(_ r: CGRect, _ hex: String, radius: CGFloat = 0) {
            c.setFillColor(UIColor(hex: hex).cgColor)
            if radius > 0 {
                c.addPath(UIBezierPath(roundedRect: r, cornerRadius: radius).cgPath); c.fillPath()
            } else { c.fill(r) }
        }

        // ── Legs ──
        fill(CGRect(x: 16, y: 30, width: 10, height: 16), "#4a5c28", radius: 2)
        fill(CGRect(x: 36, y: 30, width: 10, height: 16), "#4a5c28", radius: 2)
        fill(CGRect(x: 14, y: 42, width: 12, height: 8), "#2a1008", radius: 3)
        fill(CGRect(x: 36, y: 42, width: 12, height: 8), "#2a1008", radius: 3)

        // ── TEAL jacket ──
        fill(CGRect(x: 18, y: 18, width: 26, height: 18), "#1a7a6a", radius: 3)
        fill(CGRect(x: 18, y: 18, width: 5,  height: 18), "#0f5048", radius: 2)
        fill(CGRect(x: 39, y: 18, width: 5,  height: 18), "#0f5048", radius: 2)
        // Jacket centre seam + buttons
        c.setStrokeColor(UIColor(hex: "#28aa90").cgColor); c.setLineWidth(1)
        c.move(to: CGPoint(x:31,y:19)); c.addLine(to: CGPoint(x:31,y:35)); c.strokePath()
        for by: CGFloat in [21, 26, 31] {
            c.setFillColor(UIColor(hex: "#f5c842").cgColor)
            c.fillEllipse(in: CGRect(x:29,y:by,width:3,height:3))
        }

        // ── Belt ──
        fill(CGRect(x: 17, y: 34, width: 28, height: 4), "#5a2808")
        fill(CGRect(x: 28, y: 32, width: 8,  height: 8), "#d4a020", radius: 1)

        // ── PURPLE scarf (distinctive) ──
        fill(CGRect(x: 23, y: 15, width: 16, height: 6), "#8030a0", radius: 2)
        // Scarf tail
        fill(CGRect(x: 38, y: 15, width: 4, height: 10), "#8030a0", radius: 2)

        // ── DARK HAIR with braid ──
        fill(CGRect(x: 22, y:  7, width: 20, height:  8), "#2a1008", radius: 4)
        // Long braid down back (left side)
        fill(CGRect(x: 18, y: 10, width:  6, height: 22), "#2a1008", radius: 3)
        // Braid texture
        for by: CGFloat in [12, 17, 22, 26] {
            c.setFillColor(UIColor(hex: "#3a1808").cgColor)
            c.fillEllipse(in: CGRect(x:18,y:by,width:6,height:4))
        }
        fill(CGRect(x: 37, y: 12, width: 5, height: 6), "#2a1008", radius: 2) // right side

        // ── HEAD skin ──
        fill(CGRect(x: 22, y:  8, width: 20, height: 14), "#d4906a", radius: 6)
        // Blush
        c.setFillColor(UIColor(hex: "#e87060").withAlphaComponent(0.22).cgColor)
        c.fillEllipse(in: CGRect(x:22,y:14,width:6,height:4))
        c.fillEllipse(in: CGRect(x:34,y:14,width:6,height:4))

        // ── EYES (blue) ──
        c.setFillColor(UIColor.white.cgColor)
        c.addPath(UIBezierPath(roundedRect: CGRect(x:24,y:10,width:5,height:5), cornerRadius:2).cgPath); c.fillPath()
        c.addPath(UIBezierPath(roundedRect: CGRect(x:32,y:10,width:5,height:5), cornerRadius:2).cgPath); c.fillPath()
        c.setFillColor(UIColor(hex: "#2050c0").cgColor)  // blue eyes
        c.fillEllipse(in: CGRect(x:25,y:11,width:3,height:3))
        c.fillEllipse(in: CGRect(x:33,y:11,width:3,height:3))
        c.setFillColor(UIColor.black.cgColor)
        c.fillEllipse(in: CGRect(x:26,y:12,width:2,height:2))
        c.fillEllipse(in: CGRect(x:34,y:12,width:2,height:2))
        c.setFillColor(UIColor.white.cgColor)
        c.fill(CGRect(x:27,y:11,width:1,height:1))
        c.fill(CGRect(x:35,y:11,width:1,height:1))
        // Lashes (top of eyes)
        c.setFillColor(UIColor.black.cgColor)
        c.fill(CGRect(x:24,y: 9,width:5,height:2))
        c.fill(CGRect(x:32,y: 9,width:5,height:2))

        // ── HAT (dark teal/forest — matches jacket) ──
        fill(CGRect(x: 16, y: 5, width: 32, height: 5), "#1a5848", radius: 2) // brim
        fill(CGRect(x: 21, y: 0, width: 22, height: 9), "#1a5848", radius: 4) // crown
        fill(CGRect(x: 21, y: 0, width: 22, height: 3), "#0f3830", radius: 2) // shadow
        // Hat band (purple — matches scarf)
        fill(CGRect(x: 21, y: 5, width: 22, height: 3), "#8030a0")
        // Gold pin/brooch on hat
        c.setFillColor(UIColor(hex: "#f5c842").cgColor)
        c.fillEllipse(in: CGRect(x:28,y:3,width:6,height:6))
        c.setFillColor(UIColor(hex: "#ff6040").cgColor)
        c.fillEllipse(in: CGRect(x:30,y:5,width:3,height:3))
        // Feather
        let feather = CGMutablePath()
        feather.move(to:     CGPoint(x: 34, y: 3))
        feather.addCurve(to: CGPoint(x: 42, y: -2),
                         control1: CGPoint(x: 36, y: 0),
                         control2: CGPoint(x: 40, y: -1))
        c.setStrokeColor(UIColor(hex: "#d0e060").cgColor); c.setLineWidth(1.5)
        c.addPath(feather); c.strokePath()
    }

    // MARK: - Physics
    private func setupPhysics() {
        let physBody = SKPhysicsBody(
            rectangleOf: CGSize(width: 24, height: 72),
            center: CGPoint(x: 0, y: 36)
        )
        physBody.mass            = 1.2
        physBody.allowsRotation  = false
        physBody.restitution     = 0
        physBody.friction        = 0.0
        physBody.linearDamping   = 0
        physBody.categoryBitMask = Cat.player
        physBody.contactTestBitMask = Cat.collectible | Cat.enemy | Cat.clue | Cat.levelEnd
        physBody.collisionBitMask   = Cat.ground
        self.physicsBody = physBody
    }

    // MARK: - Controls
    func moveLeft()  { physicsBody?.velocity.dx = -moveSpeed; if  facingRight { body.xScale = -1; facingRight = false } }
    func moveRight() { physicsBody?.velocity.dx =  moveSpeed; if !facingRight { body.xScale =  1; facingRight = true  } }
    func stopHorizontal() { physicsBody?.velocity.dx = 0 }

    func jump() {
        guard isGrounded else { return }
        physicsBody?.velocity.dy = jumpForce
        isGrounded = false
        body.run(SKAction.sequence([
            SKAction.scaleX(to: 1.08, y: 0.88, duration: 0.06),
            SKAction.scaleX(to: 0.92, y: 1.10, duration: 0.09),
            SKAction.scaleX(to: 1.0,  y: 1.0,  duration: 0.10),
        ]))
    }

    func setGrounded(_ grounded: Bool) {
        isGrounded = grounded
        if grounded {
            body.run(SKAction.sequence([
                SKAction.scaleX(to: 1.10, y: 0.88, duration: 0.05),
                SKAction.scaleX(to: 1.0,  y: 1.0,  duration: 0.08),
            ]))
        }
    }

    func playHitEffect() {
        body.run(SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.9, duration: 0.06),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.38),
        ]))
        physicsBody?.applyImpulse(CGVector(dx: facingRight ? -180 : 180, dy: 320))
    }
}
