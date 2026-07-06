import Foundation

enum TerminalApp: String, Codable, CaseIterable {
    case terminal = "terminal"
    case iterm2 = "iterm2"

    var displayName: String {
        switch self {
        case .terminal: return "Terminal.app"
        case .iterm2: return "iTerm2"
        }
    }
}

struct LocalSettings: Codable {
    var terminal: TerminalApp
    var skipSwitchAlert: Bool
    var repoPaths: [String: [String: String]]

    enum CodingKeys: String, CodingKey {
        case terminal
        case skipSwitchAlert = "skip_switch_alert"
        case repoPaths = "repo_paths"
    }

    static let `default` = LocalSettings(
        terminal: .terminal,
        skipSwitchAlert: false,
        repoPaths: [:]
    )
}
