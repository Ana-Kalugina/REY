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
    private let jumpForce:  CGFloat = 580
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

    // MARK: - Sprite (62 × 80 px) — horse + rider

    private func buildSprite() {
        let sz = CGSize(width: 62, height: 80)
        let renderer = UIGraphicsImageRenderer(size: sz)
        let img = renderer.image { ctx in
            let c = ctx.cgContext
            let isFemale = characterType == .female
            drawHorse(c)
            drawRider(c, isFemale: isFemale)
        }
        body = SKSpriteNode(texture: SKTexture(image: img), size: sz)
        body.anchorPoint = CGPoint(x: 0.5, y: 0)
        addChild(body)
    }

    private func drawHorse(_ c: CGContext) {
        func fill(_ r: CGRect, _ hex: String, radius: CGFloat = 0) {
            c.setFillColor(UIColor(hex: hex).cgColor)
            if radius > 0 { c.addPath(UIBezierPath(roundedRect: r, cornerRadius: radius).cgPath); c.fillPath() }
            else { c.fill(r) }
        }

        // Body
        fill(CGRect(x: 4, y: 40, width: 50, height: 22), "#7a3a10", radius: 8)
        // Body highlight
        c.setFillColor(UIColor(hex: "#9a5a28").withAlphaComponent(0.45).cgColor)
        c.fillEllipse(in: CGRect(x: 18, y: 42, width: 20, height: 10))

        // Neck
        let neck = CGMutablePath()
        neck.move(to:    CGPoint(x: 44, y: 42))
        neck.addLine(to: CGPoint(x: 53, y: 26))
        neck.addLine(to: CGPoint(x: 60, y: 28))
        neck.addLine(to: CGPoint(x: 55, y: 44))
        neck.closeSubpath()
        c.setFillColor(UIColor(hex: "#7a3a10").cgColor)
        c.addPath(neck); c.fillPath()

        // Head
        fill(CGRect(x: 50, y: 22, width: 12, height: 18), "#7a3a10", radius: 5)
        // Nose/snout extension
        fill(CGRect(x: 56, y: 28, width: 6, height: 10), "#7a3a10", radius: 3)
        // Eye
        c.setFillColor(UIColor.black.cgColor)
        c.fillEllipse(in: CGRect(x: 58, y: 26, width: 4, height: 4))
        c.setFillColor(UIColor.white.cgColor)
        c.fill(CGRect(x: 61, y: 26, width: 1, height: 1))
        // Nostril
        c.setFillColor(UIColor(hex: "#4a1a08").cgColor)
        c.fillEllipse(in: CGRect(x: 59, y: 34, width: 3, height: 2))

        // Mane along neck
        c.setFillColor(UIColor(hex: "#2a1008").cgColor)
        for i in 0..<5 {
            let mx = CGFloat(44 + i * 3)
            let my = CGFloat(23 + i * 3)
            c.fillEllipse(in: CGRect(x: mx, y: my, width: 9, height: 5))
        }

        // Tail
        let tail = CGMutablePath()
        tail.move(to:       CGPoint(x: 8,  y: 46))
        tail.addCurve(to:   CGPoint(x: -2, y: 64),
                     control1: CGPoint(x: -2, y: 48),
                     control2: CGPoint(x: -8, y: 58))
        c.setStrokeColor(UIColor(hex: "#2a1008").cgColor)
        c.setLineWidth(4.5)
        c.addPath(tail); c.strokePath()

        // Legs — back pair (left)
        fill(CGRect(x: 10, y: 58, width: 7, height: 20), "#5a2808")
        fill(CGRect(x: 19, y: 58, width: 7, height: 20), "#5a2808")
        // Legs — front pair (right)
        fill(CGRect(x: 36, y: 58, width: 7, height: 20), "#5a2808")
        fill(CGRect(x: 45, y: 58, width: 7, height: 20), "#5a2808")

        // Hooves
        for hx: CGFloat in [9, 18, 35, 44] {
            fill(CGRect(x: hx, y: 74, width: 9, height: 6), "#1a0806", radius: 2)
        }

        // Saddle
        fill(CGRect(x: 18, y: 35, width: 28, height: 11), "#6a1010", radius: 3)
        c.setStrokeColor(UIColor(hex: "#f5c842").withAlphaComponent(0.7).cgColor)
        c.setLineWidth(1)
        c.addPath(UIBezierPath(roundedRect: CGRect(x: 18, y: 35, width: 28, height: 11), cornerRadius: 3).cgPath)
        c.strokePath()
    }

    private func drawRider(_ c: CGContext, isFemale: Bool) {
        func fill(_ r: CGRect, _ hex: String, radius: CGFloat = 0) {
            c.setFillColor(UIColor(hex: hex).cgColor)
            if radius > 0 { c.addPath(UIBezierPath(roundedRect: r, cornerRadius: radius).cgPath); c.fillPath() }
            else { c.fill(r) }
        }

        let jacketHex  = isFemale ? "#2a6a5a" : "#a07030"
        let shadowHex  = isFemale ? "#1a4a3a" : "#6a4010"
        let hairHex    = isFemale ? "#3a1808" : "#2a1008"
        let hatHex     = isFemale ? "#6a4020" : "#7a4a10"

        // Pants gripping saddle
        fill(CGRect(x: 18, y: 28, width: 10, height: 14), "#3a5028", radius: 2)
        fill(CGRect(x: 34, y: 28, width: 10, height: 14), "#3a5028", radius: 2)

        // Jacket torso
        fill(CGRect(x: 17, y: 12, width: 28, height: 20), jacketHex, radius: 3)
        // Shadow sides
        fill(CGRect(x: 17, y: 12, width: 5, height: 20), shadowHex, radius: 2)
        fill(CGRect(x: 40, y: 12, width: 5, height: 20), shadowHex, radius: 2)
        // Jacket seam
        c.setStrokeColor(UIColor(hex: shadowHex).withAlphaComponent(0.5).cgColor)
        c.setLineWidth(1)
        c.move(to: CGPoint(x: 31, y: 13)); c.addLine(to: CGPoint(x: 31, y: 31)); c.strokePath()

        // Hair
        fill(CGRect(x: 23, y: 6, width: 16, height: 10), hairHex, radius: 3)
        if isFemale {
            fill(CGRect(x: 17, y: 8, width: 7, height: 14), hairHex, radius: 3) // flowing hair
        }

        // Head skin
        fill(CGRect(x: 22, y: 6, width: 18, height: 14), "#d4906a", radius: 6)
        // Cheeks
        c.setFillColor(UIColor(hex: "#e8704a").withAlphaComponent(0.2).cgColor)
        c.fillEllipse(in: CGRect(x: 22, y: 12, width: 5, height: 4))
        c.fillEllipse(in: CGRect(x: 35, y: 12, width: 5, height: 4))

        // Eyes
        c.setFillColor(UIColor.white.cgColor)
        c.addPath(UIBezierPath(roundedRect: CGRect(x: 25, y: 9, width: 5, height: 5), cornerRadius: 2).cgPath); c.fillPath()
        c.addPath(UIBezierPath(roundedRect: CGRect(x: 32, y: 9, width: 5, height: 5), cornerRadius: 2).cgPath); c.fillPath()
        let irisHex = isFemale ? "#3d5aa0" : "#3d7a20"
        c.setFillColor(UIColor(hex: irisHex).cgColor)
        c.fillEllipse(in: CGRect(x: 26, y: 10, width: 3, height: 3))
        c.fillEllipse(in: CGRect(x: 33, y: 10, width: 3, height: 3))
        c.setFillColor(UIColor.black.cgColor)
        c.fillEllipse(in: CGRect(x: 27, y: 11, width: 2, height: 2))
        c.fillEllipse(in: CGRect(x: 34, y: 11, width: 2, height: 2))
        // Eye highlights
        c.setFillColor(UIColor.white.cgColor)
        c.fill(CGRect(x: 28, y: 10, width: 1, height: 1))
        c.fill(CGRect(x: 35, y: 10, width: 1, height: 1))

        // Hat brim
        fill(CGRect(x: 17, y: 3, width: 28, height: 4), hatHex, radius: 2)
        // Hat crown
        fill(CGRect(x: 20, y: 0, width: 22, height: 8), hatHex, radius: 3)
        // Hat band (gold for both)
        fill(CGRect(x: 20, y: 4, width: 22, height: 2), "#f5c842")
        if isFemale {
            // Flower accent
            c.setFillColor(UIColor(hex: "#e84070").cgColor)
            c.fillEllipse(in: CGRect(x: 36, y: 1, width: 5, height: 5))
        }
    }

    private func setupPhysics() {
        let physBody = SKPhysicsBody(
            rectangleOf: CGSize(width: 22, height: 70),
            center: CGPoint(x: 0, y: 35)
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

    func moveLeft() {
        physicsBody?.velocity.dx = -moveSpeed
        if facingRight { body.xScale = -1; facingRight = false }
    }

    func moveRight() {
        physicsBody?.velocity.dx = moveSpeed
        if !facingRight { body.xScale = 1; facingRight = true }
    }

    func stopHorizontal() {
        physicsBody?.velocity.dx = 0
    }

    func jump() {
        guard isGrounded else { return }
        physicsBody?.velocity.dy = jumpForce
        isGrounded = false

        // Horse jump squash/stretch
        let leap = SKAction.sequence([
            SKAction.scaleX(to: 1.1, y: 0.88, duration: 0.06),
            SKAction.scaleX(to: 0.9, y: 1.12, duration: 0.09),
            SKAction.scaleX(to: 1.0, y: 1.0,  duration: 0.1),
        ])
        body.run(leap)
    }

    func setGrounded(_ grounded: Bool) {
        isGrounded = grounded
        if grounded {
            let land = SKAction.sequence([
                SKAction.scaleX(to: 1.12, y: 0.88, duration: 0.05),
                SKAction.scaleX(to: 1.0,  y: 1.0,  duration: 0.08),
            ])
            body.run(land)
        }
    }

    func playHitEffect() {
        let flash = SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.85, duration: 0.06),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.35),
        ])
        body.run(flash)
        physicsBody?.applyImpulse(
            CGVector(dx: facingRight ? -180 : 180, dy: 320)
        )
    }
}
