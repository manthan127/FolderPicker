//
//  FileDropModifier.swift
//  ReduceProjectSize
//
//  Created by Home on 27/02/25.
//

import SwiftUI
import UniformTypeIdentifiers

public typealias URLsCompletion = (_ urls: [URL])-> Void
public typealias ErrorCompletion = (Error) -> Void

public extension View {
    func onFileDrop(
        disabled: Bool = false,
        viewModel: FolderManagerViewModel,
        filterRules: FilterRules = FilterRules(),
        onError: ErrorCompletion? = nil,
        onURLsFetched: URLsCompletion? = nil
    ) -> some View {
        self.modifier(
            FileDropModifier(
                disable: disabled,
                viewModel: viewModel,
                filterRules: filterRules,
                onError: onError,
                filesURLFetched: onURLsFetched
            )
        )
    }
    
    func onFileDrop(
        disabled: Bool = false,
        storageFilename: String? = nil,
        filterRules: FilterRules = FilterRules(),
        onError: ErrorCompletion? = nil,
        onURLsFetched: URLsCompletion? = nil
    ) -> some View {
        self.onFileDrop(
            disabled: disabled,
            viewModel: FolderManagerViewModel(storageFilename: storageFilename),
            filterRules: filterRules,
            onError: onError,
            onURLsFetched: onURLsFetched
        )
    }
}

public struct FileDropModifier: ViewModifier {
    public var disable: Bool = false
    
    @ObservedObject public var viewModel: FolderManagerViewModel
    public let filterRules: FilterRules
    public var onError: ErrorCompletion?
    public var filesURLFetched: URLsCompletion?
    
    private let fileURLIdentifier = UTType.fileURL.identifier
    
    public func body(content: Content) -> some View {
        content
            .onDrop(of: [fileURLIdentifier], isTargeted: nil, perform: filesDropAction)
    }
}

private extension FileDropModifier {
    func filesDropAction(_ providers: [NSItemProvider]) -> Bool {
        guard !disable else { return false }
        
        Task {
            let urls = await getURLs(providers)
            
            filesURLFetched?(urls)
            do {
                try viewModel.addFolders(urls)
            } catch {
                onError?(error)
            }
        }

        return true
    }
    
    func getURLs(_ providers: [NSItemProvider]) async -> [URL] {
        await withTaskGroup(of: URL?.self, returning: [URL].self) { group in
            for provider in providers where provider.hasItemConformingToTypeIdentifier(fileURLIdentifier) {
                group.addTask {
                   await getURL(provider: provider)
                }
            }
            
            return await group.arrayValue().compactMap(\.self)
        }
    }

    // TODO: - handle errors or failures
    func getURL(provider: NSItemProvider) async -> URL? {
        if let item = try? await provider.loadItem(forTypeIdentifier: fileURLIdentifier),
           let url = item.asURL(), filterRules.allows(url) {
            return url
        }
        return nil
    }
}
