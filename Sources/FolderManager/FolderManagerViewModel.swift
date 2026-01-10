//
//  FolderManagerViewModel.swift
//  basicGit
//
//  Created by Home on 20/07/25.
//

import SwiftUI
import UniformTypeIdentifiers

internal final class FolderManagerViewModel: ObservableObject {
    @Published public var folders: [URL] = []

    private let storageFilename: String
    private var bookmarkFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("FolderManager", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(storageFilename)
    }

    /// Initializes a new instance, optionally with a custom storage filename.
    ///
    /// After setting the filename, it loads the folders from the specified storage.
    ///
    /// - Parameter storageFilename: An optional custom filename for storing bookmarks.
    ///   If `nil` or blank, defaults to `"folderBookmarks.plist"`.
    public init(storageFilename: String? = nil) {
        self.storageFilename = storageFilename.nonEmptyTrimmed ?? "folderBookmarks.plist"
        
        loadFolders()
    }

    // TODO: - need to make this options more flexible for user of library
    public func pickFolder(filter: ((URL) -> Bool)?) throws {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK {
            if let url = panel.url, filter?(url) ?? true {
                try addFolder(url)
            }
        }
    }
    
    public func addFolders(_ urls: [URL]) throws {
        folders += Set(urls).filter{ $0.isFileURL && $0.hasDirectoryPath && !folders.contains($0) }
        
        try saveBookmarks()
    }

    public func addFolder(_ url: URL) throws {
        guard !folders.contains(url) else { return }

        folders.append(url)
        try saveBookmarks()
    }

    public func removeFolder(_ url: URL) throws {
        folders.removeAll { $0 == url }
        try saveBookmarks()
    }
}

private extension FolderManagerViewModel {
    func saveBookmarks() throws {
        let bookmarkDataArray: [Data] = folders.compactMap { url in
            try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
        }

        let data = try PropertyListEncoder().encode(bookmarkDataArray)
        try data.write(to: bookmarkFileURL, options: .atomic)
    }

    // TODO: - this function may cause hang if there are to many data or the file is big
    func loadFolders() {
        guard let data = try? Data(contentsOf: bookmarkFileURL),
              let bookmarkDataArray = try? PropertyListDecoder().decode([Data].self, from: data) else {
            return
        }

        for bookmarkData in bookmarkDataArray {
            var isStale = false
            do {
                let url = try URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], bookmarkDataIsStale: &isStale)
                if isStale { continue }

                folders.append(url)
            } catch {
                print("Failed to resolve bookmark: \(error)")
            }
        }
    }
}


extension Optional where Wrapped == String {
    var nonEmptyTrimmed: String? {
        if let self {
            if self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { nil }
            else { self }
        } else { nil }
    }
}
