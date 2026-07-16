import Foundation

struct TerminalResult {
    let pid: Int32?
    let tabReference: String?
    let windowReference: String?
}

final class TerminalService {
    func openInNewWindow(
        app: TerminalApp,
        repoPath: String,
        command: String,
        nodeVersion: String? = nil,
        nodeManager: NodeManager = .nvm
    ) throws -> TerminalResult {
        let fullCommand = buildFullCommand(command: command, nodeVersion: nodeVersion, nodeManager: nodeManager)
        let script: String

        switch app {
        case .terminal:
            script = buildTerminalAppNewWindowScript(repoPath: repoPath, command: fullCommand)
        case .iterm2:
            script = buildITerm2NewWindowScript(repoPath: repoPath, command: fullCommand)
        }

        let (pid, output) = try executeAppleScript(script)
        let parts = output?.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n")
        let windowRef = parts?.first
        let tabRef = parts?.last

        return TerminalResult(pid: pid, tabReference: tabRef, windowReference: windowRef)
    }

    func openInWindow(
        app: TerminalApp,
        windowReference: String,
        repoPath: String,
        command: String,
        nodeVersion: String? = nil,
        nodeManager: NodeManager = .nvm
    ) throws -> TerminalResult {
        let fullCommand = buildFullCommand(command: command, nodeVersion: nodeVersion, nodeManager: nodeManager)
        let script: String

        switch app {
        case .terminal:
            script = buildTerminalAppTabInWindowScript(windowId: windowReference, repoPath: repoPath, command: fullCommand)
        case .iterm2:
            script = buildITerm2TabInWindowScript(windowId: windowReference, repoPath: repoPath, command: fullCommand)
        }

        let (pid, output) = try executeAppleScript(script)
        let tabRef = output?.trimmingCharacters(in: .whitespacesAndNewlines)
        return TerminalResult(pid: pid, tabReference: tabRef, windowReference: windowReference)
    }

    func closeTab(app: TerminalApp, tabReference: String) {
        let script: String

        switch app {
        case .terminal:
            script = buildTerminalAppCloseScript(tabReference: tabReference)
        case .iterm2:
            script = buildITerm2CloseScript(tabReference: tabReference)
        }

        try? executeAppleScript(script)
    }

    private func buildFullCommand(command: String, nodeVersion: String?, nodeManager: NodeManager) -> String {
        if let version = nodeVersion {
            return nodeManager.wrapCommand(command, version: version)
        }
        return command
    }

    // MARK: - Terminal.app Scripts

    private func buildTerminalAppNewWindowScript(repoPath: String, command: String) -> String {
        """
        tell application "Terminal"
            set newTab to do script "cd \\"\(repoPath)\\" && \(command)"
            activate
            set windowId to id of front window
            set tabTty to tty of newTab
            return (windowId as text) & "\n" & tabTty
        end tell
        """
    }

    private func buildTerminalAppTabInWindowScript(windowId: String, repoPath: String, command: String) -> String {
        """
        tell application "Terminal"
            set targetWindow to window id \(windowId)
            set index of targetWindow to 1
        end tell
        tell application "System Events" to tell process "Terminal" to keystroke "t" using command down
        delay 0.5
        tell application "Terminal"
            set newTab to do script "cd \\"\(repoPath)\\" && \(command)" in selected tab of front window
            return tty of newTab
        end tell
        """
    }

    private func buildTerminalAppCloseScript(tabReference: String) -> String {
        """
        if application "Terminal" is not running then return
        tell application "Terminal"
            if (count of windows) is 0 then return
            repeat with w in windows
                repeat with t in tabs of w
                    try
                        if tty of t is "\(tabReference)" then
                            close t
                            return
                        end if
                    end try
                end repeat
            end repeat
        end tell
        """
    }

    // MARK: - iTerm2 Scripts

    private func buildITerm2NewWindowScript(repoPath: String, command: String) -> String {
        """
        tell application "iTerm2"
            activate
            set newWindow to (create window with default profile)
            tell current session of newWindow
                write text "cd \\"\(repoPath)\\" && \(command)"
                set sessionId to id
            end tell
            set windowId to id of newWindow
            return (windowId as text) & "\n" & sessionId
        end tell
        """
    }

    private func buildITerm2TabInWindowScript(windowId: String, repoPath: String, command: String) -> String {
        """
        tell application "iTerm2"
            repeat with w in windows
                if (id of w) as text is "\(windowId)" then
                    tell w
                        create tab with default profile
                        tell current session
                            write text "cd \\"\(repoPath)\\" && \(command)"
                            return id
                        end tell
                    end tell
                end if
            end repeat
        end tell
        """
    }

    private func buildITerm2CloseScript(tabReference: String) -> String {
        """
        tell application "iTerm2"
            repeat with w in windows
                repeat with t in tabs of w
                    repeat with s in sessions of t
                        if (id of s) is "\(tabReference)" then
                            close t
                            return
                        end if
                    end repeat
                end repeat
            end repeat
        end tell
        """
    }

    @discardableResult
    private func executeAppleScript(_ source: String) throws -> (Int32?, String?) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", source]

        let pipe = Pipe()
        process.standardOutput = pipe
        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw TerminalError.scriptFailed(errorMessage)
        }

        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8)

        return (process.processIdentifier, output)
    }
}

enum TerminalError: LocalizedError {
    case scriptFailed(String)

    var errorDescription: String? {
        switch self {
        case .scriptFailed(let message):
            return "Terminal script failed: \(message)"
        }
    }
}
