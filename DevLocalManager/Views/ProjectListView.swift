import SwiftUI

struct ProjectListView: View {
    @Bindable var viewModel: ProjectListViewModel

    var body: some View {
        List(viewModel.projects, selection: Binding(
            get: { viewModel.selectedProject?.name },
            set: { name in
                viewModel.selectedProject = viewModel.projects.first { $0.name == name }
            }
        )) { project in
            Label(project.name, systemImage: "folder.fill")
                .tag(project.name)
                .contextMenu {
                    Button {
                        viewModel.selectedProject = project
                        viewModel.isEditing = true
                    } label: {
                        Label("編輯", systemImage: "pencil")
                    }

                    Divider()

                    Button(role: .destructive) {
                        viewModel.deleteProject(project)
                    } label: {
                        Label("刪除專案", systemImage: "trash")
                    }
                }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        .safeAreaInset(edge: .bottom) {
            Button {
                viewModel.importProject()
            } label: {
                Label("匯入設定", systemImage: "plus")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
        .alert("已存在同名專案", isPresented: $viewModel.showOverwriteAlert) {
            Button("覆蓋") {
                viewModel.confirmOverwrite()
            }
            Button("取消", role: .cancel) {
                viewModel.cancelOverwrite()
            }
        } message: {
            Text("「\(viewModel.pendingProjectName ?? "")」已存在，是否覆蓋現有專案？")
        }
    }
}
