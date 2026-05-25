import SpriteKit

class EnemyNode: SKNode {

    private let patrolDistance: CGFloat
    private var startX: CGFloat = 0
    private var movingRight = true
    private let patrolSpeed: CGFloat = 70
    private var spriteNode: SKSpriteNode!

    init(patrolDistance: CGFloat) {
        self.patrolDistance = patrolDistance
        super.init()
        buildSprite()
        setupPhysics()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildSprite() {
        let size = CGSize(width: 26, height: 24)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let c = ctx.cgContext

            // Body (snake-like guard)
            c.setFillColor(UIColor(hex: "#2e4a1e").cgColor)
            c.fill(CGRect(x: 3, y: 0, width: 20, height: 16))

            // Head
            c.setFillColor(UIColor(hex: "#1e3a0e").cgColor)
            c.fill(CGRect(x: 5, y: 14, width: 16, height: 10))

            // Eyes (red, menacing)
            c.setFillColor(UIColor.red.cgColor)
            c.fill(CGRect(x: 7,  y: 18, width: 4, height: 4))
            c.fill(CGRect(x: 15, y: 18, width: 4, height: 4))

            // Spear
            c.setFillColor(UIColor(hex: "#8b7355").cgColor)
            c.fill(CGRect(x: 22, y: 0, width: 4, height: 20))
            c.setFillColor(UIColor(hex: "#c0c0c0").cgColor)
            c.fill(CGRect(x: 21, y: 18, width: 6, height: 4))
        }

        spriteNode = SKSpriteNode(texture: SKTexture(image: img), size: size)
        spriteNode.anchorPoint = CGPoint(x: 0.5, y: 0)
        addChild(spriteNode)
    }

    private func setupPhysics() {
        let physBody = SKPhysicsBody(rectangleOf: CGSize(width: 22, height: 24), center: CGPoint(x: 0, y: 12))
        physBody.isDynamic = false
        physBody.categoryBitMask = PlayerNode.Cat.enemy
        physBody.contactTestBitMask = PlayerNode.Cat.player
        physBody.collisionBitMask = 0
        self.physicsBody = physBody
    }

    func patrol() {
        if startX == 0 { startX = position.x }

        let target: CGFloat = movingRight
            ? startX + patrolDistance
            : startX - patrolDistance

        if movingRight && position.x >= target {
            movingRight = false
            spriteNode.xScale = -1
        } else if !movingRight && position.x <= target {
            movingRight = true
            spriteNode.xScale = 1
        }

        let dx = movingRight ? patrolSpeed * (1/60.0) : -patrolSpeed * (1/60.0)
        position.x += dx
    }
}
