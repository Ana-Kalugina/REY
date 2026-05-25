import SpriteKit

class TutorialNode: SKNode {

    var onComplete: (() -> Void)?

    private let viewSize: CGSize
    private var currentStep = 0
    private var panel: SKNode?

    private let steps: [(icon: String, title: String, body: String)] = [
        ("◀  ▶", "MOVE",        "Use the arrow buttons\nto run through the jungle"),
        ("▲",    "JUMP",        "Tap the gold button\nto leap over obstacles"),
        ("🔍",   "INVESTIGATE", "Walk near glowing stones\nto find hidden clues"),
        ("🏺",   "COLLECT",     "Grab gold & artifacts\nto complete daily missions"),
    ]

    init(viewSize: CGSize) {
        self.viewSize = viewSize
        super.init()
        showStep(0)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func showStep(_ index: Int) {
        panel?.removeFromParent()
        guard index < steps.count else {
            onComplete?()
            removeFromParent()
            return
        }

        let step = steps[index]
        let w: CGFloat = 280, h: CGFloat = 150
        let newPanel = SKNode()

        // Dark blurred background
        let bg = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 16)
        bg.fillColor   = UIColor(hex: "#0a1a28").withAlphaComponent(0.92)
        bg.strokeColor = UIColor(hex: "#f5c842").withAlphaComponent(0.4)
        bg.lineWidth   = 1.5
        newPanel.addChild(bg)

        // Step dots
        for i in 0..<steps.count {
            let dot = SKShapeNode(circleOfRadius: 4)
            dot.fillColor   = i == index ? UIColor(hex: "#f5c842") : UIColor.white.withAlphaComponent(0.2)
            dot.strokeColor = .clear
            dot.position    = CGPoint(x: CGFloat(i - 1) * 14 + 7, y: -h/2 + 16)
            newPanel.addChild(dot)
        }

        // Icon
        let icon = SKLabelNode(text: step.icon)
        icon.fontName   = "Courier-Bold"
        icon.fontSize   = 28
        icon.fontColor  = UIColor(hex: "#f5c842")
        icon.verticalAlignmentMode   = .center
        icon.horizontalAlignmentMode = .center
        icon.position = CGPoint(x: 0, y: 38)
        newPanel.addChild(icon)

        // Title
        let title = SKLabelNode(text: step.title)
        title.fontName   = "Courier-Bold"
        title.fontSize   = 16
        title.fontColor  = .white
        title.verticalAlignmentMode   = .center
        title.horizontalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: 10)
        newPanel.addChild(title)

        // Body (two-line)
        let lines = step.body.components(separatedBy: "\n")
        for (li, line) in lines.enumerated() {
            let lbl = SKLabelNode(text: line)
            lbl.fontName   = "Courier"
            lbl.fontSize   = 11
            lbl.fontColor  = UIColor.white.withAlphaComponent(0.65)
            lbl.verticalAlignmentMode   = .center
            lbl.horizontalAlignmentMode = .center
            lbl.position = CGPoint(x: 0, y: CGFloat(-10 - li * 14))
            newPanel.addChild(lbl)
        }

        // Tap hint
        let tapHint = SKLabelNode(text: index < steps.count - 1 ? "tap to continue →" : "tap to start playing →")
        tapHint.fontName   = "Courier"
        tapHint.fontSize   = 9
        tapHint.fontColor  = UIColor(hex: "#f5c842").withAlphaComponent(0.5)
        tapHint.verticalAlignmentMode   = .center
        tapHint.horizontalAlignmentMode = .center
        tapHint.position = CGPoint(x: 0, y: -h/2 + 30)
        newPanel.addChild(tapHint)

        // Position near bottom-center, above controls
        newPanel.position = CGPoint(x: 0, y: -viewSize.height / 2 + 160)
        newPanel.zPosition = 100
        newPanel.alpha = 0

        addChild(newPanel)
        panel = newPanel
        newPanel.run(SKAction.fadeIn(withDuration: 0.3))

        // Pulse hint
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 0.8),
            SKAction.fadeAlpha(to: 0.5, duration: 0.8),
        ])
        tapHint.run(SKAction.repeatForever(pulse))
    }

    func advance() {
        currentStep += 1
        showStep(currentStep)
    }
}
