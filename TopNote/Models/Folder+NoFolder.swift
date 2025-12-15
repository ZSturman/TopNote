//
//  Folder+NoFolder.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import Foundation

extension Folder {
    /// Sentinel option to represent cards with `folder == nil`
    static var noFolder: Folder {
        let f = Folder(name: "No Folder")
        // Use a stable UUID so selection persists.
        f.id = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        return f
    }

    var isNoFolderSentinel: Bool {
        id == UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    }
}
