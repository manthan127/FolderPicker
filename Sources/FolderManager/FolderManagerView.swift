//
//  FolderManagerView.swift
//  basicGit
//
//  Created by Home on 20/07/25.
//

import SwiftUI
import UniformTypeIdentifiers

// TODO: - need to show indicator to the user what type of file is allowed (specially for droping the files)
public struct FolderManagerView<Destination: View>: View {
    @ObservedObject var viewModel: FolderManagerViewModel
    
    private let filterRules: FilterRules
    private let onError: ErrorCompletion?
    private let destinationBuilder: (URL) -> Destination
    
    public init(
        viewModel: FolderManagerViewModel,
        filterRules: FilterRules,
        onError: ErrorCompletion? = nil,
        destination: @escaping (URL) -> Destination
    ) {
        self.destinationBuilder = destination
        self.filterRules = filterRules
        self.onError = onError
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    public init(
        storageFilename: String? = nil,
        filterRules: FilterRules,
        onError: ErrorCompletion? = nil,
        destination: @escaping (URL) -> Destination
    ) {
        self.init(
            viewModel: FolderManagerViewModel(storageFilename: storageFilename),
            filterRules: filterRules,
            onError: onError,
            destination: destination
        )
    }
    
    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                HStack {
                    Button("Choose Folder") {
                        do {
                            try viewModel.pickFolder(filterRules: filterRules)
                        } catch {
                            onError?(error)
                        }
                    }
                    
                    Spacer()
                }
                
                listView
                
                Text("Drag and drop folders here or use the button above.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
            }
            .padding()
            .navigationDestination(for: URL.self, destination: { url in
                destinationBuilder(url)
            })
            .frame(minWidth: 400, minHeight: 300)
        }
    }
    
    var listView: some View {
        List(viewModel.folders, id: \.self) { folder in
            NavigationLink(value: folder) {
                HStack {
                    Text(folder.path)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button(action: {
                        do {
                            try viewModel.removeFolder(folder)
                        } catch {
                            onError?(error)
                        }
                    }) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
        }
        .onFileDrop(viewModel: viewModel, filterRules: filterRules, onError: onError)
    }
}
