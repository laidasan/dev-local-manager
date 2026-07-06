import SwiftUI

struct ProjectDetailView: View {
    let project: ProjectConfig
    @Bindable var viewModel: ProjectDetailViewModel
    @State private var skipAlertNextTime = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerSection
            profileSection
            Divider()
            statusSection
            Spacer()
            stopSection
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .alert("切換啟動配置", isPresented: $viewModel.showSwitchAlert) {
            Button("取消", role: .cancel) {
                viewModel.pendingProfileId = nil
            }
            Button("確認切換") {
                viewModel.confirmSwitch(skipNextTime: skipAlertNextTime, project: project)
                skipAlertNextTime = false
            }
        } message: {
            Text("將停止目前執行中的服務並啟動新的配置，是否繼續？")
        }
        .alert("錯誤", isPresented: $viewModel.showError) {
            Button("確定") {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var headerSection: some View {
        Text(project.name)
            .font(.title)
            .fontWeight(.bold)
    }

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("開發環境啟用")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], alignment: .leading, spacing: 12) {
                ForEach(project.profiles) { profile in
                    let isActive = viewModel.runningSession?.profileId == profile.id
                    Button {
                        viewModel.launchProfile(profileId: profile.id, project: project)
                    } label: {
                        VStack(spacing: 4) {
                            Text(profile.label)
                                .fontWeight(.medium)
                            if let desc = profile.description {
                                Text(desc)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isActive ? .green : .accentColor)
                }
            }
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("狀態")
                .font(.headline)
                .foregroundStyle(.secondary)

            ForEach(project.repos) { repo in
                let isRunning = viewModel.runningSession?.processes
                    .contains { $0.repoId == repo.id && $0.isRunning } ?? false

                HStack(spacing: 8) {
                    Circle()
                        .fill(isRunning ? .green : .gray.opacity(0.4))
                        .frame(width: 10, height: 10)

                    Text(repo.name)
                        .frame(width: 200, alignment: .leading)

                    Text(isRunning ? "Running" : "Stopped")
                        .font(.caption)
                        .foregroundStyle(isRunning ? .green : .secondary)
                }
            }
        }
    }

    private var stopSection: some View {
        HStack {
            Spacer()
            Button(role: .destructive) {
                viewModel.stopAll()
            } label: {
                Label("全部停止", systemImage: "stop.fill")
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(viewModel.runningSession == nil)
        }
    }
}
