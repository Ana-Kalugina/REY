import SpriteKit

class ControlsNode: SKNode {

    var onLeft:          (() -> Void)?
    var onLeftRelease:   (() -> Void)?
    var onRight:         (() -> Void)?
    var onRightRelease:  (() -> Void)?
    var onJump:          (() -> Void)?

    private let viewSize: CGSize
    private var leftBtn:  ControlButton!
    private var rightBtn: ControlButton!
    private var jumpBtn:  ControlButton!

    // Track which touch is holding which button
    private var leftTouch:  UITouch?
    private var rightTouch: UITouch?

    init(viewSize: CGSize) {
        self.viewSize = viewSize
        super.init()
        isUserInteractionEnabled = true   // required — otherwise touchesBegan never fires
        buildControls()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildControls() {
        let bottomY = -viewSize.height / 2 + 56
        let leftX   = -viewSize.width  / 2 + 52

        leftBtn  = ControlButton(label: "◀", size: CGSize(width: 58, height: 58))
        leftBtn.position  = CGPoint(x: leftX, y: bottomY)
        addChild(leftBtn)

        rightBtn = ControlButton(label: "▶", size: CGSize(width: 58, height: 58))
        rightBtn.position = CGPoint(x: leftX + 70, y: bottomY)
        addChild(rightBtn)

        jumpBtn = ControlButton(label: "▲", size: CGSize(width: 66, height: 66), accent: true)
        jumpBtn.position = CGPoint(x: viewSize.width / 2 - 60, y: bottomY)
        addChild(jumpBtn)
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let loc = touch.location(in: self)
            if leftBtn.contains(loc) {
                leftTouch = touch
                onLeft?()
                leftBtn.highlight(true)
            } else if rightBtn.contains(loc) {
                rightTouch = touch
                onRight?()
                rightBtn.highlight(true)
            } else if jumpBtn.contains(loc) {
                onJump?()
                jumpBtn.highlight(true)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if touch == leftTouch {
                leftTouch = nil
                onLeftRelease?()
                leftBtn.highlight(false)
            }
            if touch == rightTouch {
                rightTouch = nil
                onRightRelease?()
                rightBtn.highlight(false)
            }
            let loc = touch.location(in: self)
            if jumpBtn.contains(loc) {
                jumpBtn.highlight(false)
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}

class ControlButton: SKShapeNode {

    init(label text: String, size: CGSize, accent: Bool = false) {
        super.init()

        let rect = CGRect(
            origin: CGPoint(x: -size.width / 2, y: -size.height / 2),
            size: size
        )
        path = UIBezierPath(roundedRect: rect, cornerRadius: 14).cgPath

        if accent {
            fillColor   = UIColor(hex: "#f5c842").withAlphaComponent(0.22)
            strokeColor = UIColor(hex: "#f5c842").withAlphaComponent(0.55)
        } else {
            fillColor   = UIColor.white.withAlphaComponent(0.10)
            strokeColor = UIColor.white.withAlphaComponent(0.30)
        }
        lineWidth = 1.5
        alpha     = 0.82
        isUserInteractionEnabled = false

        let lbl = SKLabelNode(text: text)
        lbl.fontName = "Courier-Bold"
        lbl.fontSize = accent ? 24 : 20
        lbl.fontColor = accent ? UIColor(hex: "#f5c842") : UIColor.white
        lbl.verticalAlignmentMode   = .center
        lbl.horizontalAlignmentMode = .center
        addChild(lbl)
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    func highlight(_ on: Bool) {
        alpha = on ? 1.0 : 0.82
        setScale(on ? 0.91 : 1.0)
    }
}
