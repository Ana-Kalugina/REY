import SpriteKit

class ControlsNode: SKNode {

    var onLeft:         (() -> Void)?
    var onLeftRelease:  (() -> Void)?
    var onRight:        (() -> Void)?
    var onRightRelease: (() -> Void)?
    var onJump:         (() -> Void)?

    private let viewSize: CGSize
    private var leftBtn:  ControlButton!
    private var rightBtn: ControlButton!
    private var jumpBtn:  ControlButton!

    init(viewSize: CGSize) {
        self.viewSize = viewSize
        super.init()
        buildControls()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildControls() {
        let bottomY = -viewSize.height / 2 + 50
        let leftX   = -viewSize.width  / 2 + 50

        leftBtn  = ControlButton(label: "◀", size: CGSize(width: 52, height: 52))
        leftBtn.position = CGPoint(x: leftX, y: bottomY)
        addChild(leftBtn)

        rightBtn = ControlButton(label: "▶", size: CGSize(width: 52, height: 52))
        rightBtn.position = CGPoint(x: leftX + 64, y: bottomY)
        addChild(rightBtn)

        jumpBtn = ControlButton(label: "▲", size: CGSize(width: 60, height: 60), accent: true)
        jumpBtn.position = CGPoint(x: viewSize.width / 2 - 56, y: bottomY)
        addChild(jumpBtn)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let loc = touch.location(in: self)
            if leftBtn.contains(loc)  { onLeft?();  leftBtn.highlight(true)  }
            if rightBtn.contains(loc) { onRight?(); rightBtn.highlight(true) }
            if jumpBtn.contains(loc)  { onJump?();  jumpBtn.highlight(true)  }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let loc = touch.location(in: self)
            if leftBtn.contains(loc)  { onLeftRelease?();  leftBtn.highlight(false)  }
            if rightBtn.contains(loc) { onRightRelease?(); rightBtn.highlight(false) }
            if jumpBtn.contains(loc)  { jumpBtn.highlight(false) }
        }
        // Always release both if touch ended anywhere
        if touches.count > 0 {
            onLeftRelease?()
            onRightRelease?()
            leftBtn.highlight(false)
            rightBtn.highlight(false)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}

class ControlButton: SKShapeNode {

    init(label text: String, size: CGSize, accent: Bool = false) {
        super.init()
        let rect = CGRect(origin: CGPoint(x: -size.width/2, y: -size.height/2), size: size)
        path = UIBezierPath(roundedRect: rect, cornerRadius: 10).cgPath
        fillColor   = UIColor.white.withAlphaComponent(0.12)
        strokeColor = UIColor.white.withAlphaComponent(0.25)
        lineWidth   = 1.5
        alpha       = 0.85
        isUserInteractionEnabled = false

        if accent {
            fillColor   = UIColor(hex: "#f5c842").withAlphaComponent(0.25)
            strokeColor = UIColor(hex: "#f5c842").withAlphaComponent(0.5)
        }

        let label = SKLabelNode(text: text)
        label.fontName = "Courier-Bold"
        label.fontSize = accent ? 22 : 18
        label.fontColor = accent ? UIColor(hex: "#f5c842") : .white
        label.verticalAlignmentMode = .center
        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    func highlight(_ on: Bool) {
        alpha = on ? 1.0 : 0.85
        setScale(on ? 0.92 : 1.0)
    }
}
