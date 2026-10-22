import AppKit

final class CharmView: NSView {
    override var isFlipped: Bool { true }

    var rope: Rope
    var charm: Charm { didSet { needsDisplay = true } }
    var style: StringStyle { didSet { needsDisplay = true } }
    var charmSize: CGFloat { didSet { needsDisplay = true } }

    private(set) var dragging = false
    private var dragTarget: CGPoint?
    private var grabOffset = CGPoint.zero
    private var lastBox = CGRect.null

    init(frame: NSRect, rope: Rope, charm: Charm, style: StringStyle, size: CGFloat) {
        self.rope = rope
        self.charm = charm
        self.style = style
        self.charmSize = size
        super.init(frame: frame)
        wantsLayer = true
    }
    required init?(coder: NSCoder) { fatalError("not used") }

    // MARK: geometry

    var direction: CGPoint {
        let d = rope.pos[rope.last] - rope.pos[rope.last - 1]
        let l = d.length
        return l < 0.001 ? CGPoint(x: 0, y: 1) : d * (1 / l)
    }
    var charmCenter: CGPoint { rope.pos[rope.last] + direction * (charmSize / 2) }
    func hits(_ p: CGPoint) -> Bool { (p - charmCenter).length < charmSize * 0.55 }

    // MARK: interaction

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with e: NSEvent) {
        let p = convert(e.locationInWindow, from: nil)
        guard hits(p) else { return }
        dragging = true
        grabOffset = rope.pos[rope.last] - p
        dragTarget = p
    }
    override func mouseDragged(with e: NSEvent) {
        if dragging { dragTarget = convert(e.locationInWindow, from: nil) }
    }
    override func mouseUp(with e: NSEvent) {
        dragging = false
        dragTarget = nil
    }

    func nudge(_ v: CGPoint) {
        let l = v.length
        rope.push(l > 12 ? v * (12 / l) : v)
        invalidate()
    }
    func kick() {
        rope.push(CGPoint(x: 22, y: -6))
        invalidate()
    }

    // MARK: simulation

    func tick(dt: CGFloat) {
        var pinned: CGPoint?
        if dragging, let t = dragTarget {
            var e = t + grabOffset
            let v = e - rope.anchor
            let maxL = rope.totalLength * 1.02
            if v.length > maxL { e = rope.anchor + v * (maxL / v.length) }
            pinned = e
        }
        rope.step(dt: dt, pinnedEnd: pinned)
        if dragging || rope.speed() > 0.01 { invalidate() }
    }

    private func invalidate() {
        var box = CGRect.null
        for p in rope.pos { box = box.union(CGRect(x: p.x, y: p.y, width: 1, height: 1)) }
        let r = charmSize * 0.8
        let c = charmCenter
        box = box.union(CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)).insetBy(dx: -14, dy: -14)
        setNeedsDisplay(box.union(lastBox))
        lastBox = box
    }

    // MARK: drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        drawString(ctx)
        drawCharm(ctx)
    }

    private func drawString(_ ctx: CGContext) {
        let pts = rope.pos
        switch style {
        case .thread:
            let path = CGMutablePath()
            path.move(to: pts[0])
            for i in 1..<(pts.count - 1) {
                let mid = CGPoint(x: (pts[i].x + pts[i + 1].x) / 2, y: (pts[i].y + pts[i + 1].y) / 2)
                path.addQuadCurve(to: mid, control: pts[i])
            }
            path.addLine(to: pts[pts.count - 1])
            ctx.saveGState()
            ctx.setShadow(offset: CGSize(width: 0, height: -1), blur: 2,
                          color: NSColor.black.withAlphaComponent(0.35).cgColor)
            ctx.addPath(path)
            ctx.setStrokeColor(NSColor(srgbRed: 0.72, green: 0.10, blue: 0.12, alpha: 1).cgColor)
            ctx.setLineWidth(2)
            ctx.setLineCap(.round)
            ctx.strokePath()
            ctx.restoreGState()

        case .silver, .gold:
            let base = style == .gold
                ? NSColor(srgbRed: 0.90, green: 0.74, blue: 0.30, alpha: 1)
                : NSColor(srgbRed: 0.86, green: 0.87, blue: 0.90, alpha: 1)
            let dark = style == .gold
                ? NSColor(srgbRed: 0.55, green: 0.40, blue: 0.08, alpha: 1)
                : NSColor(srgbRed: 0.42, green: 0.44, blue: 0.48, alpha: 1)

            var links: [(CGPoint, CGFloat)] = []
            let spacing: CGFloat = 5
            var carry: CGFloat = 0
            for i in 0..<(pts.count - 1) {
                let a = pts[i], d = pts[i + 1] - pts[i]
                let L = d.length
                if L < 0.001 { continue }
                let ang = atan2(d.y, d.x)
                var t = carry
                while t < L { links.append((a + d * (t / L), ang)); t += spacing }
                carry = t - L
            }
            for (k, link) in links.enumerated() {
                ctx.saveGState()
                ctx.translateBy(x: link.0.x, y: link.0.y)
                ctx.rotate(by: link.1)
                for (color, width) in [(dark, CGFloat(2.4)), (base, CGFloat(1.3))] {
                    ctx.setStrokeColor(color.cgColor)
                    ctx.setLineWidth(width)
                    if k % 2 == 0 {
                        ctx.strokeEllipse(in: CGRect(x: -3.6, y: -2.2, width: 7.2, height: 4.4))
                    } else {
                        ctx.setLineCap(.round)
                        ctx.move(to: CGPoint(x: -3.4, y: 0))
                        ctx.addLine(to: CGPoint(x: 3.4, y: 0))
                        ctx.strokePath()
                    }
                }
                ctx.restoreGState()
            }
        }
    }

    private func drawCharm(_ ctx: CGContext) {
        let end = rope.pos[rope.last]
        let d = direction
        let s = charmSize
        ctx.saveGState()
        ctx.translateBy(x: end.x, y: end.y)
        ctx.rotate(by: -atan2(d.x, d.y))
        ctx.setShadow(offset: CGSize(width: 0, height: -3), blur: 6,
                      color: NSColor.black.withAlphaComponent(0.3).cgColor)
        ctx.beginTransparencyLayer(auxiliaryInfo: nil)
        if let img = charm.image {
            let ar = img.size.width / max(img.size.height, 1)
            let w = ar > 1 ? s : s * ar
            let h = ar > 1 ? s / ar : s
            img.draw(in: CGRect(x: -w / 2, y: 0, width: w, height: h),
                     from: .zero, operation: .sourceOver, fraction: 1,
                     respectFlipped: true, hints: nil)
        } else {
            drawNazar(ctx, size: s)
        }
        ctx.endTransparencyLayer()
        ctx.restoreGState()
    }

    /// Simple built-in evil-eye bead.
    private func drawNazar(_ ctx: CGContext, size s: CGFloat) {
        ctx.setStrokeColor(NSColor(white: 0.85, alpha: 1).cgColor)
        ctx.setLineWidth(2)
        ctx.strokeEllipse(in: CGRect(x: -4, y: -2, width: 8, height: 8))

        let r = s / 2 * 0.92
        let c = CGPoint(x: 0, y: s / 2 + 3)
        let rings: [(CGFloat, NSColor)] = [
            (1.00, NSColor(srgbRed: 0.10, green: 0.22, blue: 0.62, alpha: 1)),
            (0.72, NSColor.white),
            (0.50, NSColor(srgbRed: 0.38, green: 0.65, blue: 0.95, alpha: 1)),
            (0.26, NSColor(srgbRed: 0.05, green: 0.06, blue: 0.10, alpha: 1)),
        ]
        for (f, col) in rings {
            ctx.setFillColor(col.cgColor)
            ctx.fillEllipse(in: CGRect(x: c.x - r * f, y: c.y - r * f, width: 2 * r * f, height: 2 * r * f))
        }
        ctx.setFillColor(NSColor.white.withAlphaComponent(0.8).cgColor)
        ctx.fillEllipse(in: CGRect(x: c.x - r * 0.40, y: c.y - r * 0.48, width: r * 0.18, height: r * 0.18))
    }
}
