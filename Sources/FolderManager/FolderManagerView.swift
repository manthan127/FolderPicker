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
    @StateObject var viewModel: FolderManagerViewModel
    
    let allowedFormats: [UTType]
    let filter: ((URL) -> Bool)?
    let onError: ((Error) -> ())?
    let destinationBuilder: (URL) -> Destination
    
    public init(
        storageFilename: String? = nil,
        allowedFormats: [UTType] = [],
        filter: ((URL) -> Bool)? = nil,
        onError: ((Error) -> ())? = nil,
        destination: @escaping (URL) -> Destination
    ) {
        self.destinationBuilder = destination
        self.allowedFormats = allowedFormats
        self.filter = filter
        self.onError = onError
        self._viewModel = StateObject(wrappedValue: FolderManagerViewModel(storageFilename: storageFilename))
    }
    
    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                HStack {
                    Button("Choose Folder") {
                        do {
                            try viewModel.pickFolder(allowedFormats: allowedFormats, filter: filter)
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
        .onFileDrop(allowedFormats: allowedFormats, filter: filter) { urls in
            do {
                try viewModel.addFolders(urls)
            } catch {
                onError?(error)
            }
        }
    }
}
