import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: ProjectListViewModel
    @Binding var showSettings: Bool
    @State private var settings: LocalSettings = .default
    private let configService = ConfigService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                terminalSection
                nodeManagerSection
                alertSection
                repoPathsSection
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { settings = configService.loadSettings() }
        .onChange(of: settings.terminal) { _, _ in saveSettings() }
        .onChange(of: settings.nodeManager) { _, _ in saveSettings() }
        .onChange(of: settings.skipSwitchAlert) { _, _ in saveSettings() }
    }

    private var headerSection: some View {
        HStack {
            Text("設定")
                .font(.title)
                .fontWeight(.bold)
            Spacer()
        }
    }

    private var terminalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Terminal App")
                .font(.headline)

            Picker("", selection: $settings.terminal) {
                ForEach(TerminalApp.allCases, id: \.self) { app in
                    Text(app.displayName).tag(app)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 250)
        }
    }

    private var nodeManagerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Node Version Manager")
                .font(.headline)

            Picker("", selection: $settings.nodeManager) {
                ForEach(NodeManager.allCases, id: \.self) { manager in
                    Text(manager.displayName).tag(manager)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 300)
        }
    }

    private var alertSection: some View {
        Toggle("切換 Profile 時顯示確認提醒", isOn: Binding(
            get: { !settings.skipSwitchAlert },
            set: { settings.skipSwitchAlert = !$0 }
        ))
        .toggleStyle(.checkbox)
    }

    private var repoPathsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(viewModel.projects) { project in
                VStack(alignment: .leading, spacing: 10) {
                    Text("Repo 路徑（\(project.name)）")
                        .font(.headline)

                    ForEach(project.repos) { repo in
                        HStack(spacing: 8) {
                            Text(repo.name)
                                .frame(width: 150, alignment: .leading)

                            let currentPath = settings.repoPaths[project.name]?[repo.id] ?? ""

                            TextField("選擇路徑...", text: Binding(
                                get: { currentPath },
                                set: { newValue in
                                    if settings.repoPaths[project.name] == nil {
                                        settings.repoPaths[project.name] = [:]
                                    }
                                    settings.repoPaths[project.name]?[repo.id] = newValue
                                    saveSettings()
                                }
                            ))
                            .textFieldStyle(.roundedBorder)

                            Button {
                                selectFolder(for: repo.id, projectName: project.name)
                            } label: {
                                Image(systemName: "folder")
                            }
                        }
                    }
                }
            }
        }
    }

    private func selectFolder(for repoId: String, projectName: String) {
        let panel = NSOpenPanel()
        panel.title = "選擇 Repo 路徑"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        if settings.repoPaths[projectName] == nil {
            settings.repoPaths[projectName] = [:]
        }
        settings.repoPaths[projectName]?[repoId] = url.path
        saveSettings()
    }

    private func saveSettings() {
        configService.saveSettings(settings)
    }
}
