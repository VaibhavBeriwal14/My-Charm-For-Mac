import AppKit

struct Charm {
    let name: String
    let image: NSImage?   // nil = built-in drawn Nazar
}

enum CharmLibrary {
    static var userFolder: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MyCharm/Charms", isDirectory: true)
    }

    static func ensureFolder() {
        try? FileManager.default.createDirectory(at: userFolder, withIntermediateDirectories: true)
    }

    static func all() -> [Charm] {
        var list = [Charm(name: "NAZAR", image: nil)]
        var urls: [URL] = []
        let fm = FileManager.default
        if let res = Bundle.main.resourceURL?.appendingPathComponent("Charms"),
           let c = try? fm.contentsOfDirectory(at: res, includingPropertiesForKeys: nil) {
            urls += c
        }
        ensureFolder()
        if let c = try? fm.contentsOfDirectory(at: userFolder, includingPropertiesForKeys: nil) {
            urls += c
        }
        let exts: Set<String> = ["png", "jpg", "jpeg", "heic", "tif", "tiff"]
        for u in urls.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
        where exts.contains(u.pathExtension.lowercased()) {
            if let img = NSImage(contentsOf: u) {
                list.append(Charm(name: u.deletingPathExtension().lastPathComponent, image: img))
            }
        }
        return list
    }
}
