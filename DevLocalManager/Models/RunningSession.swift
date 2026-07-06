import Foundation

struct RunningSession: Identifiable {
    let id = UUID()
    let projectName: String
    let profileId: String
    var windowReference: String?
    var processes: [RunningProcess]
}

struct RunningProcess: Identifiable {
    let id = UUID()
    let repoId: String
    let repoName: String
    let serviceId: String
    let serviceLabel: String
    let command: String
    var pid: Int32?
    var tabReference: String?
    let startedAt: Date
    var isRunning: Bool
}
