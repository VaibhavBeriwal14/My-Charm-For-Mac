import CoreGraphics

extension CGPoint {
    static func + (a: CGPoint, b: CGPoint) -> CGPoint { CGPoint(x: a.x + b.x, y: a.y + b.y) }
    static func - (a: CGPoint, b: CGPoint) -> CGPoint { CGPoint(x: a.x - b.x, y: a.y - b.y) }
    static func * (a: CGPoint, s: CGFloat) -> CGPoint { CGPoint(x: a.x * s, y: a.y * s) }
    var length: CGFloat { hypot(x, y) }
}

/// Verlet rope. Coordinates are flipped (y grows downward).
struct Rope {
    static let count = 14
    var pos: [CGPoint]
    var prev: [CGPoint]
    var anchor: CGPoint
    private(set) var segLen: CGFloat

    var last: Int { Rope.count - 1 }
    var totalLength: CGFloat { segLen * CGFloat(Rope.count - 1) }

    init(anchor: CGPoint, length: CGFloat) {
        self.anchor = anchor
        let seg = length / CGFloat(Rope.count - 1)
        segLen = seg
        pos = (0..<Rope.count).map { CGPoint(x: anchor.x, y: anchor.y + CGFloat($0) * seg) }
        prev = pos
    }

    mutating func setLength(_ l: CGFloat) { segLen = l / CGFloat(Rope.count - 1) }

    mutating func reset() {
        for i in 0..<Rope.count {
            pos[i] = CGPoint(x: anchor.x, y: anchor.y + CGFloat(i) * segLen)
            prev[i] = pos[i]
        }
    }

    /// Adds velocity (px per frame) to the charm end.
    mutating func push(_ v: CGPoint) { prev[last] = prev[last] - v }

    func speed() -> CGFloat {
        var m: CGFloat = 0
        for i in 0..<Rope.count { m = max(m, (pos[i] - prev[i]).length) }
        return m
    }

    mutating func step(dt: CGFloat, pinnedEnd: CGPoint?) {
        let gravity: CGFloat = 2000
        let damping: CGFloat = 0.996

        for i in 1..<Rope.count {
            let v = (pos[i] - prev[i]) * damping
            prev[i] = pos[i]
            pos[i] = pos[i] + v + CGPoint(x: 0, y: gravity * dt * dt)
        }
        pos[0] = anchor
        prev[0] = anchor
        if let p = pinnedEnd { pos[last] = p }   // prev keeps old pos -> flick velocity on release

        for _ in 0..<20 {
            for i in 0..<(Rope.count - 1) {
                let j = i + 1
                let wa: CGFloat = (i == 0) ? 0 : 1
                var wb: CGFloat = (j == last) ? 0.3 : 1      // charm is heavier
                if j == last && pinnedEnd != nil { wb = 0 }
                let sum = wa + wb
                if sum == 0 { continue }
                let d = pos[j] - pos[i]
                let dist = max(d.length, 0.0001)
                let corr = d * ((dist - segLen) / dist / sum)
                pos[i] = pos[i] + corr * wa
                pos[j] = pos[j] - corr * wb
            }
        }
    }
}
