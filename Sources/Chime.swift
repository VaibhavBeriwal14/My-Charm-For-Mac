import AVFoundation

/// Synthesised wind-chime sound, no audio file needed.
@MainActor
enum Chime {
    private static var player: AVAudioPlayer?
    private static let wav: Data = makeWav()

    static func play() {
        player = try? AVAudioPlayer(data: wav)
        player?.volume = 0.8
        player?.play()
    }

    private static func makeWav() -> Data {
        let sr = 44100.0, dur = 4.0
        let n = Int(sr * dur)
        var buf = [Double](repeating: 0, count: n)
        let notes: [(Double, Double)] = [
            (1046.50, 0.00), (1567.98, 0.18), (1318.51, 0.42), (2093.00, 0.70),
            (1760.00, 1.05), (1318.51, 1.45), (2349.32, 1.80)
        ]
        for (f, start) in notes {
            let s0 = Int(start * sr)
            for i in s0..<n {
                let t = Double(i - s0) / sr
                let env = min(1, t * 400) * exp(-t * 1.8)
                let v = sin(2 * .pi * f * t)
                    + 0.35 * sin(2 * .pi * f * 2.76 * t) * exp(-t * 4)
                    + 0.15 * sin(2 * .pi * f * 5.40 * t) * exp(-t * 8)
                buf[i] += v * env
            }
        }
        let peak = max(buf.map { abs($0) }.max() ?? 1, 0.0001)
        let pcm: [Int16] = buf.map { Int16(max(-1, min(1, $0 / peak * 0.7)) * 32767) }

        var d = Data()
        func str(_ s: String) { d.append(s.data(using: .ascii)!) }
        func u32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { d.append(contentsOf: $0) } }
        func u16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { d.append(contentsOf: $0) } }
        str("RIFF"); u32(UInt32(36 + n * 2)); str("WAVE")
        str("fmt "); u32(16); u16(1); u16(1); u32(44100); u32(88200); u16(2); u16(16)
        str("data"); u32(UInt32(n * 2))
        pcm.withUnsafeBytes { d.append(contentsOf: $0) }
        return d
    }
}
