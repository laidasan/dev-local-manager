import SwiftUI

struct MainView: View {
    @State private var listViewModel = ProjectListViewModel()
    @State private var detailViewModel = ProjectDetailViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationSplitView {
            ProjectListView(viewModel: listViewModel)
        } detail: {
            if showSettings {
                SettingsView(
                    viewModel: listViewModel,
                    showSettings: $showSettings
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
                Button {
                    showSettings.toggle()
                } label: {
                    Image(systemName: showSettings ? "xmark" : "gearshape")
                }
                .help(showSettings ? "關閉設定" : "設定")
            }
        }
        .frame(minWidth: 700, minHeight: 450)
        .onAppear {
            listViewModel.loadProjects()
        }
        .alert("錯誤", isPresented: $listViewModel.showError) {
            Button("確定") {}
        } message: {
            Text(listViewModel.errorMessage ?? "")
        }
    }
}
