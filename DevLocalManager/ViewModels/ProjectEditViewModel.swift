import Foundation

@MainActor
@Observable
final class ProjectEditViewModel {
    var repoEdits: [RepoEdit] = []
    var errorMessage: String?
    var showError = false

    private var originalConfig: ProjectConfig?
    private let configService = ConfigService()

    struct RepoEdit: Identifiable {
        let id: String
        let name: String
        var nodeVersion: String
        var environments: [EnvironmentEdit]
    }

    struct EnvironmentEdit: Identifiable {
        let environmentId: String
        var services: [ServiceEdit]

        var id: String { environmentId }
    }

    struct ServiceEdit: Identifiable {
        let id: String
        let label: String
        var command: String
    }

    func load(from config: ProjectConfig) {
        originalConfig = config
        repoEdits = config.repos.map { repo in
            let envEdits = repo.environments.map { (envId, envConfig) in
                EnvironmentEdit(
                    environmentId: envId,
                    services: envConfig.services.map { service in
                        ServiceEdit(id: service.id, label: service.label, command: service.command)
                    }
                )
            }.sorted { $0.environmentId < $1.environmentId }

            return RepoEdit(
                id: repo.id,
                name: repo.name,
                nodeVersion: repo.nodeVersion ?? "",
                environments: envEdits
            )
        }
    }

    func save() -> ProjectConfig? {
        guard let original = originalConfig else { return nil }

        let updatedRepos = original.repos.map { repo in
            guard let edit = repoEdits.first(where: { $0.id == repo.id }) else { return repo }

            let updatedEnvironments = repo.environments.mapValues { envConfig in
                guard let envEdit = edit.environments.first(where: { $0.environmentId == envConfig.services.first?.id ?? "" }) else {
                    return envConfig
                }
                return envConfig
            }

            var newEnvironments: [String: RepoEnvironmentConfig] = [:]
            for (envId, envConfig) in repo.environments {
                guard let envEdit = edit.environments.first(where: { $0.environmentId == envId }) else {
                    newEnvironments[envId] = envConfig
                    continue
                }

                let updatedServices = envConfig.services.map { service in
                    guard let serviceEdit = envEdit.services.first(where: { $0.id == service.id }) else {
                        return service
                    }
                    return ServiceConfig(id: service.id, label: service.label, command: serviceEdit.command)
                }

                newEnvironments[envId] = RepoEnvironmentConfig(
                    preCommands: envConfig.preCommands,
                    services: updatedServices,
                    envFile: envConfig.envFile
                )
            }

            return RepoConfig(
                id: repo.id,
                name: repo.name,
                nodeVersion: edit.nodeVersion.isEmpty ? nil : edit.nodeVersion,
                environments: newEnvironments
            )
        }

        let updatedConfig = ProjectConfig(
            name: original.name,
            environments: original.environments,
            repos: updatedRepos,
            profiles: original.profiles
        )

        do {
            try configService.saveProjectConfig(updatedConfig)
            return updatedConfig
        } catch {
            errorMessage = "儲存失敗：\(error.localizedDescription)"
            showError = true
            return nil
        }
    }
}
