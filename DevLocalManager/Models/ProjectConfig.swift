import Foundation

struct ProjectConfig: Codable, Identifiable {
    let name: String
    let environments: [Environment]
    let repos: [RepoConfig]
    let profiles: [Profile]

    var id: String { name }
}

struct Environment: Codable, Identifiable {
    let id: String
    let label: String
    let description: String?
}

struct RepoConfig: Codable, Identifiable {
    let id: String
    let name: String
    let nodeVersion: String?
    let environments: [String: RepoEnvironmentConfig]

    enum CodingKeys: String, CodingKey {
        case id, name, environments
        case nodeVersion = "node_version"
    }
}

struct RepoEnvironmentConfig: Codable {
    let preCommands: [String]?
    let services: [ServiceConfig]
    let envFile: EnvFileConfig?

    enum CodingKeys: String, CodingKey {
        case preCommands = "pre_commands"
        case services
        case envFile = "env_file"
    }
}

struct ServiceConfig: Codable, Identifiable {
    let id: String
    let label: String
    let command: String
}

struct EnvFileConfig: Codable {
    let path: String
    let variables: [String: String]
}

struct ProfileRepoConfig: Codable {
    let environment: String
    let services: [String]?
}

struct Profile: Codable, Identifiable {
    let id: String
    let label: String
    let description: String?
    let repos: [String: ProfileRepoConfig]
    let startupOrder: [String]

    enum CodingKeys: String, CodingKey {
        case id, label, description, repos
        case startupOrder = "startup_order"
    }
}
