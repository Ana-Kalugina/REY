import SpriteKit

enum CollectibleType {
    case gold
    case artifact
}

class CollectibleNode: SKNode {

    let collectibleType: CollectibleType
    private var sprite: SKShapeNode!

    init(type: CollectibleType) {
        self.collectibleType = type
        super.init()
        buildSprite()
        setupPhysics()
        addFloatAnimation()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildSprite() {
        switch collectibleType {
        case .gold:
            sprite = SKShapeNode(circleOfRadius: 8)
            sprite.fillColor = UIColor(hex: "#f5c842")
            sprite.strokeColor = UIColor(hex: "#d4a017")
            sprite.lineWidth = 1.5

            // Inner detail
            let inner = SKShapeNode(circleOfRadius: 4)
            inner.fillColor = UIColor(hex: "#ffd700")
            inner.strokeColor = .clear
            sprite.addChild(inner)

            // "$" label
            let label = SKLabelNode(text: "G")
            label.fontName = "Courier-Bold"
            label.fontSize = 9
            label.fontColor = UIColor(hex: "#7a5000")
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            sprite.addChild(label)

        case .artifact:
            sprite = SKShapeNode(rectOf: CGSize(width: 18, height: 22), cornerRadius: 3)
            sprite.fillColor = UIColor(hex: "#c0822e")
            sprite.strokeColor = UIColor(hex: "#f5c842")
            sprite.lineWidth = 2

            let glow = SKShapeNode(rectOf: CGSize(width: 22, height: 26), cornerRadius: 4)
            glow.fillColor = UIColor(hex: "#f5c842").withAlphaComponent(0.18)
            glow.strokeColor = .clear
            glow.zPosition = -1
            sprite.addChild(glow)

            let label = SKLabelNode(text: "🏺")
            label.fontSize = 12
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            sprite.addChild(label)
        }

        addChild(sprite)
    }

    private func setupPhysics() {
        let radius: CGFloat = collectibleType == .gold ? 10 : 14
        let body = SKPhysicsBody(circleOfRadius: radius)
        body.isDynamic = false
        body.categoryBitMask = PlayerNode.Cat.collectible
        body.contactTestBitMask = PlayerNode.Cat.player
        body.collisionBitMask = 0
        physicsBody = body
    }

    private func addFloatAnimation() {
        let up   = SKAction.moveBy(x: 0, y: 5,  duration: 0.9)
        let down = SKAction.moveBy(x: 0, y: -5, duration: 0.9)
        up.timingMode = .easeInEaseOut
        down.timingMode = .easeInEaseOut
        sprite.run(SKAction.repeatForever(SKAction.sequence([up, down])))

        if collectibleType == .gold {
            let spin = SKAction.rotate(byAngle: .pi * 2, duration: 2.5)
            // Coin shimmer via alpha pulse
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.7, duration: 0.4),
                SKAction.fadeAlpha(to: 1.0, duration: 0.4),
            ])
            sprite.run(SKAction.repeatForever(pulse))
        }
    }

    func collect(in scene: SKScene) {
        let pop = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.6, duration: 0.15),
                SKAction.fadeOut(withDuration: 0.15),
            ]),
            SKAction.removeFromParent(),
        ])
        run(pop)

        // Particle burst
        for _ in 0..<6 {
            let dot = SKShapeNode(circleOfRadius: 3)
            dot.fillColor = collectibleType == .gold ? UIColor(hex: "#f5c842") : UIColor(hex: "#c0822e")
            dot.strokeColor = .clear
            dot.position = position
            dot.zPosition = zPosition + 1
            scene.addChild(dot)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist: CGFloat = CGFloat.random(in: 20...40)
            let burst = SKAction.group([
                SKAction.move(by: CGVector(dx: cos(angle) * dist, dy: sin(angle) * dist), duration: 0.35),
                SKAction.fadeOut(withDuration: 0.35),
            ])
            dot.run(SKAction.sequence([burst, SKAction.removeFromParent()]))
        }
    }
}
