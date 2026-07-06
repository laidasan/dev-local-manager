import Foundation

@MainActor
@Observable
final class UpdateService {
    enum State: Equatable {
        case idle
        case updateAvailable(version: String)
        case updating
        case updateComplete
        case error(String)
    }

    var state: State = .idle

    private let repoOwner = "laidasan"
    private let repoName = "dev-local-manager"

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    func checkForUpdate() async {
        guard let url = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest") else { return }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            let latestVersion = release.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))

            if latestVersion != currentVersion {
                state = .updateAvailable(version: latestVersion)
            }
        } catch {
            // silently fail - update check is non-critical
        }
    }

    func performUpdate() async {
        state = .updating

        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/local/bin/brew")

            if !FileManager.default.fileExists(atPath: "/usr/local/bin/brew") {
                process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/brew")
            }

            process.arguments = ["upgrade", "--cask", "dev-local-manager"]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            try process.run()

            await withCheckedContinuation { continuation in
                process.terminationHandler = { _ in
                    continuation.resume()
                }
            }

            if process.terminationStatus == 0 {
                state = .updateComplete
            } else {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                state = .error("更新失敗：\(output)")
            }
        } catch {
            state = .error("更新失敗：\(error.localizedDescription)")
        }
    }
}

private struct GitHubRelease: Decodable {
    let tagName: String

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
    }
}
