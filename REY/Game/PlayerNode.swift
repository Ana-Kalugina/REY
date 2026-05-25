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

    private let moveSpeed: CGFloat = 230
    private let jumpForce: CGFloat = 580
    private var isGrounded  = false
    private var facingRight = true
    private var body: SKSpriteNode!

    override init() {
        super.init()
        buildSprite()
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    // MARK: - Sprite  (28 × 46 px, UIKit coords: y=0 is top of image)

    private func buildSprite() {
        let sz = CGSize(width: 28, height: 46)
        let renderer = UIGraphicsImageRenderer(size: sz)
        let img = renderer.image { ctx in
            let c = ctx.cgContext

            func fill(_ r: CGRect, _ hex: String, radius: CGFloat = 0) {
                c.setFillColor(UIColor(hex: hex).cgColor)
                if radius > 0 {
                    c.addPath(UIBezierPath(roundedRect: r, cornerRadius: radius).cgPath)
                    c.fillPath()
                } else {
                    c.fill(r)
                }
            }

            // ── HAT (top of image = top of character) ──
            fill(CGRect(x: 2,  y: 0,  width: 24, height: 5), "#8a5c18", radius: 2)  // brim
            fill(CGRect(x: 6,  y: 1,  width: 16, height: 9), "#9a6c20", radius: 3)  // crown
            fill(CGRect(x: 6,  y: 8,  width: 16, height: 2), "#d4a020")             // hat band
            // Hat highlight
            c.setFillColor(UIColor(hex: "#c0882a").withAlphaComponent(0.5).cgColor)
            c.addPath(UIBezierPath(roundedRect: CGRect(x: 7, y: 2, width: 6, height: 6), cornerRadius: 2).cgPath)
            c.fillPath()

            // ── HAIR ──
            fill(CGRect(x: 5, y: 8, width: 18, height: 7), "#5a2c0c", radius: 3)
            fill(CGRect(x: 4, y: 12, width: 4, height: 6), "#5a2c0c", radius: 2)   // left strand
            fill(CGRect(x: 20, y: 12, width: 4, height: 5), "#5a2c0c", radius: 2)  // right strand

            // ── HEAD ──
            fill(CGRect(x: 5, y: 12, width: 18, height: 14), "#d4906a", radius: 6)
            // cheek flush
            c.setFillColor(UIColor(hex: "#e8704a").withAlphaComponent(0.25).cgColor)
            c.fillEllipse(in: CGRect(x: 6, y: 18, width: 5, height: 4))
            c.fillEllipse(in: CGRect(x: 17, y: 18, width: 5, height: 4))

            // ── EYES ──
            // whites
            c.setFillColor(UIColor.white.cgColor)
            c.addPath(UIBezierPath(roundedRect: CGRect(x: 8, y: 16, width: 5, height: 5), cornerRadius: 2).cgPath)
            c.fillPath()
            c.addPath(UIBezierPath(roundedRect: CGRect(x: 15, y: 16, width: 5, height: 5), cornerRadius: 2).cgPath)
            c.fillPath()
            // irises (green)
            c.setFillColor(UIColor(hex: "#3d7a20").cgColor)
            c.fillEllipse(in: CGRect(x: 9, y: 17, width: 3, height: 3))
            c.fillEllipse(in: CGRect(x: 16, y: 17, width: 3, height: 3))
            // pupils
            c.setFillColor(UIColor.black.cgColor)
            c.fillEllipse(in: CGRect(x: 10, y: 18, width: 2, height: 2))
            c.fillEllipse(in: CGRect(x: 17, y: 18, width: 2, height: 2))
            // eye highlights
            c.setFillColor(UIColor.white.cgColor)
            c.fill(CGRect(x: 11, y: 17, width: 1, height: 1))
            c.fill(CGRect(x: 18, y: 17, width: 1, height: 1))

            // ── SCARF / NECK ──
            fill(CGRect(x: 8,  y: 25, width: 12, height: 3), "#c8301a", radius: 1)
            fill(CGRect(x: 10, y: 27, width: 4, height: 5), "#d4906a")  // neck

            // ── JACKET (khaki explorer) ──
            fill(CGRect(x: 3, y: 28, width: 22, height: 10), "#a07030", radius: 3)
            // jacket shadow on sides
            c.setFillColor(UIColor(hex: "#6a4010").withAlphaComponent(0.4).cgColor)
            c.addPath(UIBezierPath(roundedRect: CGRect(x: 3, y: 28, width: 4, height: 10), cornerRadius: 2).cgPath)
            c.fillPath()
            c.addPath(UIBezierPath(roundedRect: CGRect(x: 21, y: 28, width: 4, height: 10), cornerRadius: 2).cgPath)
            c.fillPath()
            // jacket centre seam
            c.setStrokeColor(UIColor(hex: "#6a4010").withAlphaComponent(0.5).cgColor)
            c.setLineWidth(1)
            c.move(to: CGPoint(x: 14, y: 29)); c.addLine(to: CGPoint(x: 14, y: 37)); c.strokePath()

            // ── BELT ──
            fill(CGRect(x: 3, y: 37, width: 22, height: 3), "#6a3010")
            fill(CGRect(x: 11, y: 36, width: 6, height: 5), "#d4a020", radius: 1) // buckle

            // ── PANTS ──
            fill(CGRect(x: 4, y: 39, width: 9, height: 4), "#3a5028", radius: 2)
            fill(CGRect(x: 15, y: 39, width: 9, height: 4), "#3a5028", radius: 2)

            // ── BOOTS ──
            fill(CGRect(x: 3,  y: 42, width: 10, height: 4), "#2a1808", radius: 2)
            fill(CGRect(x: 15, y: 42, width: 10, height: 4), "#2a1808", radius: 2)
            // boot highlight
            c.setFillColor(UIColor(hex: "#4a2c10").withAlphaComponent(0.6).cgColor)
            c.fillEllipse(in: CGRect(x: 4, y: 42, width: 4, height: 2))
            c.fillEllipse(in: CGRect(x: 16, y: 42, width: 4, height: 2))
        }

        body = SKSpriteNode(texture: SKTexture(image: img), size: sz)
        body.anchorPoint = CGPoint(x: 0.5, y: 0)
        addChild(body)
    }

    private func setupPhysics() {
        let physBody = SKPhysicsBody(
            rectangleOf: CGSize(width: 20, height: 44),
            center: CGPoint(x: 0, y: 22)
        )
        physBody.mass             = 1.0
        physBody.allowsRotation   = false
        physBody.restitution      = 0
        physBody.friction         = 0.0
        physBody.linearDamping    = 0
        physBody.categoryBitMask  = Cat.player
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

        let squash  = SKAction.scaleX(to: 1.2, y: 0.8, duration: 0.07)
        let stretch = SKAction.scaleX(to: 0.85, y: 1.15, duration: 0.09)
        let restore = SKAction.scaleX(to: 1.0, y: 1.0, duration: 0.1)
        body.run(SKAction.sequence([squash, stretch, restore]))
    }

    func setGrounded(_ grounded: Bool) {
        isGrounded = grounded
        if grounded {
            let land = SKAction.sequence([
                SKAction.scaleX(to: 1.15, y: 0.85, duration: 0.05),
                SKAction.scaleX(to: 1.0,  y: 1.0,  duration: 0.09),
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
            CGVector(dx: facingRight ? -140 : 140, dy: 280)
        )
    }
}
