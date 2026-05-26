import SpriteKit

// Display-only node — touch handling lives in GameScene for reliability
class ControlsNode: SKNode {

    enum Btn { case left, right, jump }

    private var leftBtn:  ControlButton!
    private var rightBtn: ControlButton!
    private var jumpBtn:  ControlButton!

    private let viewSize: CGSize

    init(viewSize: CGSize) {
        self.viewSize = viewSize
        super.init()
        buildControls()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildControls() {
        let bottomY = -viewSize.height / 2 + 44
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

    func highlight(_ btn: Btn, on: Bool) {
        switch btn {
        case .left:  leftBtn.highlight(on)
        case .right: rightBtn.highlight(on)
        case .jump:  jumpBtn.highlight(on)
        }
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
        lbl.fontName  = "Courier-Bold"
        lbl.fontSize  = accent ? 24 : 20
        lbl.fontColor = accent ? UIColor(hex: "#f5c842") : UIColor.white
        lbl.verticalAlignmentMode   = .center
        lbl.horizontalAlignmentMode = .center
        addChild(lbl)
    }

    required init?(coder: NSCoder) { fatalError() }

    func highlight(_ on: Bool) {
        alpha    = on ? 1.0 : 0.82
        setScale(on ? 0.91 : 1.0)
    }
}
