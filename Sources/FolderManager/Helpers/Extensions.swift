//
//  File.swift
//  FolderManager
//
//  Created by macm4 on 22/01/26.
//

import UniformTypeIdentifiers

extension NSSecureCoding {
    func asURL() -> URL? {
        if let data = self as? Data {
            return URL(dataRepresentation: data, relativeTo: nil)
        }
        return nil
    }
}

extension URL {
    var fileType: UTType? {
        try? self.resourceValues(forKeys: [.contentTypeKey]).contentType
    }
    
    func conformsAny(_ types: [UTType])-> Bool {
        if let fileType {
            return types.contains(where: { fileType.conforms(to: $0) })
        }
        return false
    }
}

extension String {
    var nonEmptyTrimmed: String? {
        self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}
