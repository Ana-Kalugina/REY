import SpriteKit

class ClueNode: SKNode {

    let clue: Clue
    private var examined = false
    private var indicator: SKNode!

    init(clue: Clue) {
        self.clue = clue
        super.init()
        buildSprite()
        setupPhysics()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildSprite() {
        // Stone block
        let block = SKShapeNode(rectOf: CGSize(width: 28, height: 28), cornerRadius: 4)
        block.fillColor = UIColor(hex: "#5c4a28")
        block.strokeColor = UIColor(hex: "#f5c842")
        block.lineWidth = 1.5
        addChild(block)

        // Clue symbol
        let label = SKLabelNode(text: "🔍")
        label.fontSize = 14
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        block.addChild(label)

        // Pulsing "!" indicator above
        let dot = SKShapeNode(circleOfRadius: 5)
        dot.fillColor = UIColor(hex: "#f5c842")
        dot.strokeColor = .clear
        dot.position = CGPoint(x: 0, y: 26)

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5),
        ])
        dot.run(SKAction.repeatForever(pulse))

        let excl = SKLabelNode(text: "!")
        excl.fontName = "Courier-Bold"
        excl.fontSize = 8
        excl.fontColor = UIColor(hex: "#0d1b2a")
        excl.verticalAlignmentMode = .center
        dot.addChild(excl)

        indicator = dot
        addChild(indicator)
    }

    private func setupPhysics() {
        let body = SKPhysicsBody(rectangleOf: CGSize(width: 30, height: 30))
        body.isDynamic = false
        body.categoryBitMask = PlayerNode.Cat.clue
        body.contactTestBitMask = PlayerNode.Cat.player
        body.collisionBitMask = 0
        physicsBody = body
    }

    func examine() {
        guard !examined else { return }
        examined = true
        indicator.removeFromParent()

        // Gold flash
        let flash = SKAction.sequence([
            SKAction.colorize(with: UIColor(hex: "#f5c842"), colorBlendFactor: 0.8, duration: 0.1),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.4),
        ])
        children.first?.run(flash)
    }
}
