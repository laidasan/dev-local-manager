import Foundation

final class EnvFileService {
    func applyEnvFile(config: EnvFileConfig, repoPath: String) throws {
        let filePath = (repoPath as NSString).appendingPathComponent(config.path)
        let fileURL = URL(fileURLWithPath: filePath)

        var pendingVars = config.variables
        var lines = loadLines(at: fileURL)

        for i in lines.indices {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

            if let eqIndex = trimmed.firstIndex(of: "=") {
                let key = String(trimmed[trimmed.startIndex..<eqIndex])
                    .trimmingCharacters(in: .whitespaces)
                if let newValue = pendingVars.removeValue(forKey: key) {
                    lines[i] = "\(key)=\(newValue)"
                }
            }
        }

        for (key, value) in pendingVars.sorted(by: { $0.key < $1.key }) {
            lines.append("\(key)=\(value)")
        }

        let content = lines.joined(separator: "\n") + "\n"

        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private func loadLines(at url: URL) -> [String] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }
        var lines = content.components(separatedBy: .newlines)
        if lines.last == "" { lines.removeLast() }
        return lines
    }
}
