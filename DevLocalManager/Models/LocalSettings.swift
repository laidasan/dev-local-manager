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

enum NodeManager: String, Codable, CaseIterable {
    case nvm
    case fnm
    case volta
    case mise

    var displayName: String {
        switch self {
        case .nvm:   return "nvm"
        case .fnm:   return "fnm"
        case .volta: return "Volta"
        case .mise:  return "mise"
        }
    }

    func wrapCommand(_ command: String, version: String) -> String {
        switch self {
        case .nvm:   return "nvm use \(version) && \(command)"
        case .fnm:   return "fnm use \(version) && \(command)"
        case .volta: return "volta run --node \(version) \(command)"
        case .mise:  return "mise use node@\(version) && \(command)"
        }
    }
}

struct LocalSettings: Codable {
    var terminal: TerminalApp
    var nodeManager: NodeManager
    var skipSwitchAlert: Bool
    var repoPaths: [String: [String: String]]

    enum CodingKeys: String, CodingKey {
        case terminal
        case nodeManager = "node_manager"
        case skipSwitchAlert = "skip_switch_alert"
        case repoPaths = "repo_paths"
    }

    static let `default` = LocalSettings(
        terminal: .terminal,
        nodeManager: .nvm,
        skipSwitchAlert: false,
        repoPaths: [:]
    )
}
