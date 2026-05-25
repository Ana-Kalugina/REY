import SpriteKit

class PlayerNode: SKNode {

    // MARK: - Physics categories (mirror GameScene)
    struct Cat {
        static let player:     UInt32 = 0x1 << 0
        static let ground:     UInt32 = 0x1 << 1
        static let collectible:UInt32 = 0x1 << 2
        static let enemy:      UInt32 = 0x1 << 3
        static let clue:       UInt32 = 0x1 << 4
        static let levelEnd:   UInt32 = 0x1 << 5
    }

    private let moveSpeed:  CGFloat = 220
    private let jumpForce:  CGFloat = 560
    private let maxFall:    CGFloat = -900
    private var isGrounded  = false
    private var facingRight = true

    private var body: SKSpriteNode!
    private var head: SKShapeNode!

    override init() {
        super.init()
        buildSprite()
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    // MARK: - Sprite

    private func buildSprite() {
        let size = CGSize(width: 22, height: 32)

        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext

            // Boots (dark brown)
            c.setFillColor(UIColor(hex: "#3d2000").cgColor)
            c.fill(CGRect(x: 2, y: 0, width: 8, height: 7))
            c.fill(CGRect(x: 12, y: 0, width: 8, height: 7))

            // Trousers (deep burgundy)
            c.setFillColor(UIColor(hex: "#6b1a1a").cgColor)
            c.fill(CGRect(x: 2, y: 7, width: 18, height: 8))

            // Belt (gold)
            c.setFillColor(UIColor(hex: "#f5c842").cgColor)
            c.fill(CGRect(x: 2, y: 14, width: 18, height: 3))

            // Shirt (warm tan)
            c.setFillColor(UIColor(hex: "#c08040").cgColor)
            c.fill(CGRect(x: 3, y: 17, width: 16, height: 8))

            // Neck/skin
            c.setFillColor(UIColor(hex: "#e8a87c").cgColor)
            c.fill(CGRect(x: 8, y: 24, width: 6, height: 4))

            // Head
            c.fill(CGRect(x: 5, y: 26, width: 12, height: 11))

            // Eyes
            c.setFillColor(UIColor(hex: "#1a1a2e").cgColor)
            c.fill(CGRect(x: 7, y: 32, width: 3, height: 3))
            c.fill(CGRect(x: 12, y: 32, width: 3, height: 3))

            // Hat (explorer hat, tan)
            c.setFillColor(UIColor(hex: "#a07030").cgColor)
            c.fill(CGRect(x: 3, y: 36, width: 16, height: 4))   // brim
            c.fill(CGRect(x: 6, y: 38, width: 10, height: 5))   // crown
        }

        body = SKSpriteNode(texture: SKTexture(image: img), size: size)
        body.anchorPoint = CGPoint(x: 0.5, y: 0)
        addChild(body)
    }

    private func setupPhysics() {
        let physBody = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: 32), center: CGPoint(x: 0, y: 16))
        physBody.mass = 1.0
        physBody.allowsRotation = false
        physBody.restitution = 0
        physBody.friction = 0.0
        physBody.linearDamping = 0
        physBody.categoryBitMask = Cat.player
        physBody.contactTestBitMask = Cat.collectible | Cat.enemy | Cat.clue | Cat.levelEnd
        physBody.collisionBitMask = Cat.ground
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

        // Squash & stretch
        let squash = SKAction.scaleX(to: 1.2, y: 0.8, duration: 0.06)
        let stretch = SKAction.scaleX(to: 0.85, y: 1.2, duration: 0.08)
        let normal = SKAction.scaleX(to: 1.0, y: 1.0, duration: 0.1)
        body.run(SKAction.sequence([squash, stretch, normal]))
    }

    func setGrounded(_ grounded: Bool) {
        isGrounded = grounded
        if grounded {
            // Land squash
            let land = SKAction.sequence([
                SKAction.scaleX(to: 1.15, y: 0.85, duration: 0.05),
                SKAction.scaleX(to: 1.0,  y: 1.0,  duration: 0.08),
            ])
            body.run(land)
        }
    }

    func playHitEffect() {
        let flash = SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.9, duration: 0.05),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.3),
        ])
        body.run(flash)
        physicsBody?.applyImpulse(CGVector(dx: facingRight ? -120 : 120, dy: 250))
    }
}
