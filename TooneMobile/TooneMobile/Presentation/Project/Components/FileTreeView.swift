import SwiftUI

// MARK: - File Tree View

struct FileTreeView: View {
    let files: [ProjectFile]
    let expandedPaths: Set<String>
    let depth: Int
    let onSelectFile: (ProjectFile) -> Void

    var body: some View {
        ForEach(sortedFiles) { file in
            VStack(spacing: 0) {
                FileRow(
                    file: file,
                    depth: depth,
                    isExpanded: expandedPaths.contains(file.path)
                ) {
                    onSelectFile(file)
                }

                // Recursive children
                if file.isDirectory,
                   expandedPaths.contains(file.path),
                   let children = file.children
                {
                    FileTreeView(
                        files: children,
                        expandedPaths: expandedPaths,
                        depth: depth + 1,
                        onSelectFile: onSelectFile
                    )
                }
            }
        }
    }

    // MARK: - Sorting

    private var sortedFiles: [ProjectFile] {
        files.sorted { lhs, rhs in
            // Directories first, then alphabetical
            if lhs.isDirectory && !rhs.isDirectory { return true }
            if !lhs.isDirectory && rhs.isDirectory { return false }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        OceanDepth.darkBase.ignoresSafeArea()

        ScrollView {
            LazyVStack(spacing: 0) {
                FileTreeView(
                    files: [
                        ProjectFile(
                            id: "1",
                            name: "Sources",
                            path: "/Sources",
                            isDirectory: true,
                            children: [
                                ProjectFile(
                                    id: "2",
                                    name: "App.swift",
                                    path: "/Sources/App.swift",
                                    isDirectory: false,
                                    children: nil,
                                    size: 1024,
                                    modifiedAt: nil
                                ),
                                ProjectFile(
                                    id: "3",
                                    name: "ContentView.swift",
                                    path: "/Sources/ContentView.swift",
                                    isDirectory: false,
                                    children: nil,
                                    size: 2048,
                                    modifiedAt: nil
                                ),
                            ],
                            size: nil,
                            modifiedAt: nil
                        ),
                        ProjectFile(
                            id: "4",
                            name: "README.md",
                            path: "/README.md",
                            isDirectory: false,
                            children: nil,
                            size: 512,
                            modifiedAt: nil
                        ),
                    ],
                    expandedPaths: ["/Sources"],
                    depth: 0,
                    onSelectFile: { _ in }
                )
            }
        }
    }
}
