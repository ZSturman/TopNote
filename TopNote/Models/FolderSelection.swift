//
//  FolderSelection.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import Foundation


enum FolderSelection: Identifiable, Equatable, Hashable {
    case allCards
    case folder(Folder)
    
    // For 'allCards', use a fixed UUID so that it remains constant.
    var id: UUID {
        switch self {
        case .allCards:
            return UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        case .folder(let folder):
            return folder.id
        }
    }
    
    var name: String {
        switch self {
        case .allCards:
            return "All Cards"
        case .folder(let folder):
            return folder.name
        }
    }
}
