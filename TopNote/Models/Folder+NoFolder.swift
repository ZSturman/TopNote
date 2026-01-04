//
//  Folder+NoFolder.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import Foundation

extension Folder {
    /// The sentinel UUID used to identify the "No Folder" option
    private static let noFolderUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    
    /// Cached singleton instance of the noFolder sentinel.
    /// Using nonisolated(unsafe) for thread-safe lazy initialization.
    private static var _noFolderCache: Folder?
    
    /// Sentinel option to represent cards with `folder == nil`.
    /// Returns a cached singleton instance to ensure consistent identity across comparisons.
    static var noFolder: Folder {
        if let cached = _noFolderCache {
            return cached
        }
        let f = Folder(name: "No Folder")
        f.id = noFolderUUID
        _noFolderCache = f
        return f
    }

    /// Checks if this folder is the "No Folder" sentinel.
    var isNoFolderSentinel: Bool {
        id == Folder.noFolderUUID
    }
}
