//
//  SelectedFolderStatView.swift
//  TopNote
//
//  Created by Zachary Sturman on 3/1/25.
//

import Foundation
import SwiftUI

struct SelectedFolderStatView: View {
    var folder: FolderSelection = .allCards
    var cards: [Card]

    
    
    var body: some View {
        VStack {
            Text("Selected Folder Stats")
            Text("\(cards.count)")
        }
    }
}
