import SwiftUI

struct ProjectEditView: View {
    let project: ProjectConfig
    @Bindable var viewModel: ProjectEditViewModel
    var onSave: (ProjectConfig) -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("編輯：\(project.name)")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach($viewModel.repoEdits) { $repoEdit in
                        repoSection(repoEdit: $repoEdit)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            Divider()

            HStack {
                Spacer()
                Button("取消") {
                    onCancel()
                }
                .keyboardShortcut(.escape, modifiers: [])

                Button("確定") {
                    if let updated = viewModel.save() {
                        onSave(updated)
                    }
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            viewModel.load(from: project)
        }
        .alert("錯誤", isPresented: $viewModel.showError) {
            Button("確定") {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func repoSection(repoEdit: Binding<ProjectEditViewModel.RepoEdit>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(repoEdit.wrappedValue.name)
                .font(.headline)

            LabeledContent("Node Version") {
                TextField("例如 18.17.0", text: repoEdit.nodeVersion)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            }

            ForEach(repoEdit.environments) { envEdit in
                environmentSection(
                    repoEdit: repoEdit,
                    envEdit: envEdit
                )
            }
        }
        .padding(16)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func environmentSection(
        repoEdit: Binding<ProjectEditViewModel.RepoEdit>,
        envEdit: Binding<ProjectEditViewModel.EnvironmentEdit>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("環境：\(envEdit.wrappedValue.environmentId)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(envEdit.services) { $serviceEdit in
                HStack(spacing: 12) {
                    Text(serviceEdit.label)
                        .frame(width: 120, alignment: .leading)
                        .foregroundStyle(.secondary)

                    TextField("command", text: $serviceEdit.command)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .padding(.leading, 8)
    }
}
