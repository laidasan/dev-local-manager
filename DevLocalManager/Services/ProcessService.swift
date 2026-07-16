import Foundation

final class ProcessService {
    private var runningSession: RunningSession?
    private var terminalApp: TerminalApp = .terminal

    var currentSession: RunningSession? { runningSession }

    var hasRunningProcesses: Bool {
        runningSession?.processes.contains { $0.isRunning } ?? false
    }

    func startSession(projectName: String, profileId: String, terminalApp: TerminalApp) -> RunningSession {
        self.terminalApp = terminalApp
        let session = RunningSession(
            projectName: projectName,
            profileId: profileId,
            processes: []
        )
        runningSession = session
        return session
    }

    func setWindowReference(_ windowRef: String?) {
        runningSession?.windowReference = windowRef
    }

    var windowReference: String? {
        runningSession?.windowReference
    }

    func addProcess(repoId: String, repoName: String, serviceId: String, serviceLabel: String, command: String, pid: Int32?, tabReference: String?) {
        let process = RunningProcess(
            repoId: repoId,
            repoName: repoName,
            serviceId: serviceId,
            serviceLabel: serviceLabel,
            command: command,
            pid: pid,
            tabReference: tabReference,
            startedAt: Date(),
            isRunning: true
        )
        runningSession?.processes.append(process)
    }

    func stopService(serviceId: String, terminalService: TerminalService) {
        guard let session = runningSession,
              let index = session.processes.firstIndex(where: { $0.serviceId == serviceId && $0.isRunning })
        else { return }

        let process = session.processes[index]

        killProcess(process)

        if let tabRef = process.tabReference {
            terminalService.closeTab(app: terminalApp, tabReference: tabRef)
        }

        runningSession?.processes[index].isRunning = false
    }

    func stopAll(terminalService: TerminalService) {
        guard let session = runningSession else { return }

        for process in session.processes where process.isRunning {
            killProcess(process)
        }

        for process in session.processes where process.isRunning {
            if let tabRef = process.tabReference {
                terminalService.closeTab(app: terminalApp, tabReference: tabRef)
            }
        }

        runningSession = nil
    }

    private func killProcess(_ process: RunningProcess) {
        switch terminalApp {
        case .terminal:
            guard let tabRef = process.tabReference else { return }
            let ttyName = (tabRef as NSString).lastPathComponent
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/bin/sh")
            proc.arguments = ["-c", "pkill -t \(ttyName) 2>/dev/null; sleep 0.2; pkill -9 -t \(ttyName) 2>/dev/null || true"]
            try? proc.run()
            proc.waitUntilExit()
        case .iterm2:
            if let pid = process.pid {
                kill(pid, SIGTERM)
            }
        }
    }
}
