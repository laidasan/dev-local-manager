import Foundation
import SwiftUI

@MainActor
@Observable
final class ProjectListViewModel {
    var projects: [ProjectConfig] = []
    var selectedProject: ProjectConfig?
    var errorMessage: String?
    var showError = false
    var isEditing = false
    var showOverwriteAlert = false
    var pendingImportURL: URL?
    var pendingProjectName: String?

    private let configService = ConfigService()

    func loadProjects() {
        projects = configService.loadAllProjects()
        if selectedProject == nil {
            selectedProject = projects.first
        }
    }

    func importProject() {
        let panel = NSOpenPanel()
        panel.title = "匯入設定"
        panel.allowedContentTypes = [.yaml]
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        if let existingName = configService.projectExists(at: url) {
            pendingImportURL = url
            pendingProjectName = existingName
            showOverwriteAlert = true
        } else {
            performImport(from: url)
        }
    }

    func confirmOverwrite() {
        guard let url = pendingImportURL else { return }
        performImport(from: url)
        pendingImportURL = nil
        pendingProjectName = nil
    }

    func cancelOverwrite() {
        pendingImportURL = nil
        pendingProjectName = nil
    }

    func deleteProject(_ project: ProjectConfig) {
        configService.deleteProject(project)
        if selectedProject?.name == project.name {
            selectedProject = nil
        }
        loadProjects()
    }

    private func performImport(from url: URL) {
        do {
            let config = try configService.importProject(from: url)
            loadProjects()
            selectedProject = projects.first { $0.name == config.name }
        } catch {
            errorMessage = "匯入失敗：\(error.localizedDescription)"
            showError = true
        }
    }
}
