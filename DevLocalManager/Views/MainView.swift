import SwiftUI

struct MainView: View {
    @State private var listViewModel = ProjectListViewModel()
    @State private var detailViewModel = ProjectDetailViewModel()
    @State private var editViewModel = ProjectEditViewModel()
    @State private var updateService = UpdateService()
    @State private var showSettings = false
    @State private var showUpdatePopover = false

    var body: some View {
        NavigationSplitView {
            ProjectListView(viewModel: listViewModel)
        } detail: {
            if showSettings {
                SettingsView(
                    viewModel: listViewModel,
                    showSettings: $showSettings
                )
            } else if listViewModel.isEditing, let project = listViewModel.selectedProject {
                ProjectEditView(
                    project: project,
                    viewModel: editViewModel,
                    onSave: { updatedConfig in
                        listViewModel.isEditing = false
                        listViewModel.loadProjects()
                        listViewModel.selectedProject = listViewModel.projects.first { $0.name == updatedConfig.name }
                    },
                    onCancel: {
                        listViewModel.isEditing = false
                    }
                )
            } else if let project = listViewModel.selectedProject {
                ProjectDetailView(
                    project: project,
                    viewModel: detailViewModel
                )
            } else {
                ContentUnavailableView(
                    "尚未選擇專案",
                    systemImage: "folder.badge.questionmark",
                    description: Text("請從左側選擇專案，或點擊「+ 匯入專案」")
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                HStack(spacing: 8) {
                    updateToolbarItem

                    Button {
                        showSettings.toggle()
                    } label: {
                        Image(systemName: showSettings ? "xmark" : "gearshape")
                    }
                    .help(showSettings ? "關閉設定" : "設定")
                }
            }
        }
        .frame(minWidth: 700, minHeight: 450)
        .onAppear {
            listViewModel.loadProjects()
        }
        .task {
            await updateService.checkForUpdate()
        }
        .alert("錯誤", isPresented: $listViewModel.showError) {
            Button("確定") {}
        } message: {
            Text(listViewModel.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var updateToolbarItem: some View {
        switch updateService.state {
        case .idle:
            EmptyView()

        case .updateAvailable(let version):
            Button {
                showUpdatePopover = true
            } label: {
                Label("有新版本", systemImage: "arrow.down.circle")
                    .foregroundStyle(.orange)
            }
            .help("有新版本 v\(version) 可用")
            .popover(isPresented: $showUpdatePopover, arrowEdge: .bottom) {
                VStack(spacing: 12) {
                    Text("新版本 v\(version) 可用")
                        .font(.headline)

                    Text("目前版本：v\(updateService.currentVersion)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Button("取消") {
                            showUpdatePopover = false
                        }

                        Button("確定") {
                            showUpdatePopover = false
                            Task {
                                await updateService.performUpdate()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(16)
            }

        case .updating:
            ProgressView()
                .controlSize(.small)
                .help("更新中...")

        case .updateComplete:
            Text("更新完成，請重新啟動 App")
                .font(.caption)
                .foregroundStyle(.green)

        case .error(let message):
            Button {
                showUpdatePopover = true
            } label: {
                Label("更新失敗", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            }
            .help(message)
            .popover(isPresented: $showUpdatePopover, arrowEdge: .bottom) {
                VStack(spacing: 12) {
                    Text("更新失敗")
                        .font(.headline)

                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: 250)

                    Button("關閉") {
                        showUpdatePopover = false
                    }
                }
                .padding(16)
            }
        }
    }
}
