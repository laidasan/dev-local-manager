import Foundation
import Yams

final class ConfigService {
    private let projectsDirectory: URL
    private let settingsFileURL: URL

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!.appendingPathComponent("DevLocalManager")

        self.projectsDirectory = appSupport.appendingPathComponent("projects")
        self.settingsFileURL = appSupport.appendingPathComponent("settings.yaml")

        try? FileManager.default.createDirectory(
            at: projectsDirectory,
            withIntermediateDirectories: true
        )
    }

    // MARK: - Project Config

    func loadAllProjects() -> [ProjectConfig] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: projectsDirectory,
            includingPropertiesForKeys: nil
        ) else { return [] }

        return files
            .filter { $0.pathExtension == "yaml" || $0.pathExtension == "yml" }
            .compactMap { loadProjectConfig(from: $0) }
    }

    func projectExists(at sourceURL: URL) -> String? {
        guard let data = try? Data(contentsOf: sourceURL),
              let config = try? YAMLDecoder().decode(ProjectConfig.self, from: data)
        else { return nil }

        let destFileName = config.name
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            + ".yaml"
        let destURL = projectsDirectory.appendingPathComponent(destFileName)

        if FileManager.default.fileExists(atPath: destURL.path) {
            return config.name
        }
        return nil
    }

    func importProject(from sourceURL: URL) throws -> ProjectConfig {
        let data = try Data(contentsOf: sourceURL)
        let config = try YAMLDecoder().decode(ProjectConfig.self, from: data)

        let destFileName = config.name
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            + ".yaml"
        let destURL = projectsDirectory.appendingPathComponent(destFileName)

        try data.write(to: destURL)
        return config
    }

    func saveProjectConfig(_ config: ProjectConfig) throws {
        let fileName = config.name
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            + ".yaml"
        let destURL = projectsDirectory.appendingPathComponent(fileName)
        let yamlString = try YAMLEncoder().encode(config)
        try yamlString.write(to: destURL, atomically: true, encoding: .utf8)
    }

    func deleteProject(_ project: ProjectConfig) {
        let fileName = project.name
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            + ".yaml"
        let fileURL = projectsDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func loadProjectConfig(from url: URL) -> ProjectConfig? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? YAMLDecoder().decode(ProjectConfig.self, from: data)
    }

    // MARK: - Local Settings

    func loadSettings() -> LocalSettings {
        guard let data = try? Data(contentsOf: settingsFileURL),
              let settings = try? YAMLDecoder().decode(LocalSettings.self, from: data)
        else {
            return .default
        }
        return settings
    }

    func saveSettings(_ settings: LocalSettings) {
        guard let yamlString = try? YAMLEncoder().encode(settings) else { return }
        try? yamlString.write(to: settingsFileURL, atomically: true, encoding: .utf8)
    }
}
