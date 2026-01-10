//
//  FileDropModifier.swift
//  ReduceProjectSize
//
//  Created by Home on 27/02/25.
//

import SwiftUI
import UniformTypeIdentifiers

public typealias URLsCompletion = (_ urls: [URL])-> Void

public extension View {
    func onFileDrop(
        disabled: Bool = false,
        allowedFormats: [UTType] = [UTType.directory],
        filter: ((URL) -> Bool)? = nil,
        onURLsFetched: @escaping URLsCompletion
    ) -> some View {
        self.modifier(
            FileDropModifier(
                disable: disabled,
                allowedFormats: allowedFormats,
                filter: filter,
                filesURLFetched: onURLsFetched
            )
        )
    }
}

public struct FileDropModifier: ViewModifier {
    public var disable: Bool = false
    public var allowedFormats: [UTType] = []
    public var filter: ((URL) -> Bool)? = nil
    public var filesURLFetched: URLsCompletion
    
    public func body(content: Content) -> some View {
        content
            .onDrop(of: [UTType.fileURL.identifier], isTargeted: nil, perform: filesDropAction)
    }

    private func filesDropAction(_ providers: [NSItemProvider]) -> Bool {
        guard !disable else { return false }

        var urls: [URL] = []
        let dispatchGroup = DispatchGroup()
        // TODO: -  handle errors or failures
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                dispatchGroup.enter()
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    defer { dispatchGroup.leave() }

                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        let formatIsAllowed = allowedFormats.isEmpty || url.conformsAny(allowedFormats)
                        let passesFilter = filter?(url) ?? true
                        
                        if formatIsAllowed && passesFilter {
                            urls.append(url)
                        }
                    }
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            filesURLFetched(urls)
        }

        return true
    }
}

extension URL {
    var fileType: UTType? {
        try? self.resourceValues(forKeys: [.contentTypeKey]).contentType
    }
    
    func conformsAny(_ types: [UTType])-> Bool {
        fileType.map { fileType in
            types.contains(where: { fileType.conforms(to: $0) })
        } ?? false
    }
}
