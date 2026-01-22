//
//  FilterRules.swift
//  FolderManager
//
//  Created by macm4 on 22/01/26.
//

import UniformTypeIdentifiers

public struct FilterRules {
    public let allowedFormats: [UTType]
    public let filter: ((URL) -> Bool)?
    
    public init(
        allowedFormats: [UTType] = [],
        filter: ((URL) -> Bool)? = nil
    ) {
        self.allowedFormats = allowedFormats
        self.filter = filter
    }
    
    func allows(_ url: URL) -> Bool {
        let formatIsAllowed = allowedFormats.isEmpty || url.conformsAny(allowedFormats)
        let passesFilter = filter?(url) ?? true
        return formatIsAllowed && passesFilter
    }
}
