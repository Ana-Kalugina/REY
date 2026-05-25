import SpriteKit

class HUDNode: SKNode {

    private var goldLabel:    SKLabelNode!
    private var livesRow:     SKNode!
    private let viewSize:     CGSize
    private var lives = 3
    private var gold = 0

    init(viewSize: CGSize) {
        self.viewSize = viewSize
        super.init()
        buildHUD()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildHUD() {
        let topY  =  viewSize.height / 2 - 28
        let leftX = -viewSize.width  / 2 + 20

        // Background bar
        let bar = SKShapeNode(rectOf: CGSize(width: viewSize.width, height: 44))
        bar.fillColor = UIColor(hex: "#0d1b2a").withAlphaComponent(0.7)
        bar.strokeColor = UIColor(hex: "#f5c842").withAlphaComponent(0.2)
        bar.lineWidth = 1
        bar.position = CGPoint(x: 0, y: topY + 6)
        addChild(bar)

        // Gold counter
        let goldIcon = SKLabelNode(text: "💰")
        goldIcon.fontSize = 16
        goldIcon.verticalAlignmentMode = .center
        goldIcon.position = CGPoint(x: leftX + 16, y: topY)
        addChild(goldIcon)

        goldLabel = SKLabelNode(text: "0")
        goldLabel.fontName = "Courier-Bold"
        goldLabel.fontSize = 16
        goldLabel.fontColor = UIColor(hex: "#f5c842")
        goldLabel.verticalAlignmentMode = .center
        goldLabel.horizontalAlignmentMode = .left
        goldLabel.position = CGPoint(x: leftX + 34, y: topY)
        addChild(goldLabel)

        // Lives
        livesRow = SKNode()
        livesRow.position = CGPoint(x: viewSize.width / 2 - 100, y: topY)
        addChild(livesRow)
        refreshLives()

        // Title
        let title = SKLabelNode(text: "REY")
        title.fontName = "Courier-Bold"
        title.fontSize = 14
        title.fontColor = UIColor(hex: "#f5c842").withAlphaComponent(0.6)
        title.verticalAlignmentMode = .center
        title.horizontalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: topY)
        addChild(title)
    }

    func updateGold(_ value: Int) {
        gold = value
        goldLabel.text = "\(value)"

        let pop = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.08),
            SKAction.scale(to: 1.0, duration: 0.12),
        ])
        goldLabel.run(pop)
    }

    func loseLife() {
        lives = max(0, lives - 1)
        refreshLives()
    }

    private func refreshLives() {
        livesRow.removeAllChildren()
        for i in 0..<3 {
            let heart = SKLabelNode(text: i < lives ? "❤️" : "🖤")
            heart.fontSize = 14
            heart.verticalAlignmentMode = .center
            heart.position = CGPoint(x: CGFloat(i) * 20, y: 0)
            livesRow.addChild(heart)
        }
    }

    func showFloatingText(_ text: String, at position: CGPoint, color: UIColor = UIColor(hex: "#f5c842")) {
        let label = SKLabelNode(text: text)
        label.fontName = "Courier-Bold"
        label.fontSize = 18
        label.fontColor = color
        label.position = position
        label.zPosition = 50
        parent?.addChild(label)

        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 50, duration: 0.6),
                SKAction.fadeOut(withDuration: 0.6),
            ]),
            SKAction.removeFromParent(),
        ]))
    }
}
