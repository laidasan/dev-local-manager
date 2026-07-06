import Foundation
import SwiftUI

@MainActor
@Observable
final class ProjectDetailViewModel {
    var runningSession: RunningSession?
    var showSwitchAlert = false
    var pendingProfileId: String?
    var errorMessage: String?
    var showError = false

    private let configService = ConfigService()
    private let envFileService = EnvFileService()
    private let terminalService = TerminalService()
    private let processService = ProcessService()

    var settings: LocalSettings {
        configService.loadSettings()
    }

    func launchProfile(profileId: String, project: ProjectConfig) {
        if processService.hasRunningProcesses {
            let currentSettings = configService.loadSettings()
            if currentSettings.skipSwitchAlert {
                stopAllAndLaunch(profileId: profileId, project: project)
            } else {
                pendingProfileId = profileId
                showSwitchAlert = true
            }
            return
        }

        performLaunch(profileId: profileId, project: project)
    }

    func confirmSwitch(skipNextTime: Bool, project: ProjectConfig) {
        if skipNextTime {
            var currentSettings = configService.loadSettings()
            currentSettings.skipSwitchAlert = true
            configService.saveSettings(currentSettings)
        }

        guard let profileId = pendingProfileId else { return }
        stopAllAndLaunch(profileId: profileId, project: project)
        pendingProfileId = nil
    }

    func stopAll() {
        processService.stopAll(terminalService: terminalService)
        runningSession = nil
    }

    func restartService(serviceId: String, repoId: String, project: ProjectConfig) {
        guard let session = runningSession,
              let process = session.processes.first(where: { $0.serviceId == serviceId && $0.isRunning }),
              let repo = project.repos.first(where: { $0.id == repoId }),
              let windowRef = processService.windowReference
        else { return }

        let currentSettings = configService.loadSettings()

        processService.stopService(serviceId: serviceId, terminalService: terminalService)

        do {
            let repoPath = currentSettings.repoPaths[project.name]?[repoId] ?? ""
            let result = try terminalService.openInWindow(
                app: currentSettings.terminal,
                windowReference: windowRef,
                repoPath: repoPath,
                command: process.command,
                nodeVersion: repo.nodeVersion
            )

            processService.addProcess(
                repoId: repoId,
                repoName: process.repoName,
                serviceId: serviceId,
                serviceLabel: process.serviceLabel,
                command: process.command,
                pid: result.pid,
                tabReference: result.tabReference
            )
            runningSession = processService.currentSession
        } catch {
            errorMessage = "重啟 \(process.serviceLabel) 失敗：\(error.localizedDescription)"
            showError = true
        }
    }

    private func stopAllAndLaunch(profileId: String, project: ProjectConfig) {
        processService.stopAll(terminalService: terminalService)
        performLaunch(profileId: profileId, project: project)
    }

    private func performLaunch(profileId: String, project: ProjectConfig) {
        guard let profile = project.profiles.first(where: { $0.id == profileId }) else { return }

        let currentSettings = configService.loadSettings()
        let repoPaths = currentSettings.repoPaths[project.name] ?? [:]

        _ = processService.startSession(
            projectName: project.name,
            profileId: profileId,
            terminalApp: currentSettings.terminal
        )

        var windowRef: String?

        for repoId in profile.startupOrder {
            guard let profileRepoConfig = profile.repos[repoId],
                  let repo = project.repos.first(where: { $0.id == repoId }),
                  let envConfig = repo.environments[profileRepoConfig.environment],
                  let repoPath = repoPaths[repoId]
            else { continue }

            let selectedServiceIds = profileRepoConfig.services
            let servicesToLaunch = selectedServiceIds != nil
                ? envConfig.services.filter { selectedServiceIds!.contains($0.id) }
                : envConfig.services

            do {
                if let envFileConfig = envConfig.envFile {
                    try envFileService.applyEnvFile(config: envFileConfig, repoPath: repoPath)
                }

                for service in servicesToLaunch {
                    let result: TerminalResult

                    if let existingWindow = windowRef {
                        result = try terminalService.openInWindow(
                            app: currentSettings.terminal,
                            windowReference: existingWindow,
                            repoPath: repoPath,
                            command: service.command,
                            nodeVersion: repo.nodeVersion
                        )
                    } else {
                        result = try terminalService.openInNewWindow(
                            app: currentSettings.terminal,
                            repoPath: repoPath,
                            command: service.command,
                            nodeVersion: repo.nodeVersion
                        )
                        windowRef = result.windowReference
                        processService.setWindowReference(windowRef)
                    }

                    processService.addProcess(
                        repoId: repoId,
                        repoName: repo.name,
                        serviceId: service.id,
                        serviceLabel: service.label,
                        command: service.command,
                        pid: result.pid,
                        tabReference: result.tabReference
                    )
                }
            } catch {
                errorMessage = "\(repo.name) 啟動失敗：\(error.localizedDescription)"
                showError = true
            }
        }

        runningSession = processService.currentSession
    }
}
