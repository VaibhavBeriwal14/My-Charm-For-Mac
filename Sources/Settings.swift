import Foundation

enum StringStyle: String, CaseIterable {
    case thread, silver, gold

    var title: String {
        switch self {
        case .thread: return "Classic Thread"
        case .silver: return "Silver Chain"
        case .gold:   return "Gold Chain"
        }
    }
}

@MainActor
final class Settings {
    static let shared = Settings()
    private let d = UserDefaults.standard

    var charmSize: Double {
        get { d.object(forKey: "charmSize") as? Double ?? 90 }
        set { d.set(newValue, forKey: "charmSize") }
    }
    var stringLength: Double {
        get { d.object(forKey: "stringLength") as? Double ?? 180 }
        set { d.set(newValue, forKey: "stringLength") }
    }
    /// 0...1 across the screen width
    var position: Double {
        get { d.object(forKey: "position") as? Double ?? 0.8 }
        set { d.set(newValue, forKey: "position") }
    }
    var style: StringStyle {
        get { StringStyle(rawValue: d.string(forKey: "style") ?? "") ?? .thread }
        set { d.set(newValue.rawValue, forKey: "style") }
    }
    var charmName: String {
        get { d.string(forKey: "charmName") ?? "NAZAR" }
        set { d.set(newValue, forKey: "charmName") }
    }
    var hidden: Bool {
        get { d.bool(forKey: "hidden") }
        set { d.set(newValue, forKey: "hidden") }
    }
}
