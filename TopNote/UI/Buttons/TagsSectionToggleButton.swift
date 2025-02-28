//
//  TagsSectionToggleButton.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/24/25.
//

import Foundation
import SwiftUI

struct TagsButton: View {
    @Binding var showingTagSelection: Bool
    
    var body: some View {
        Button(action: {showingTagSelection.toggle()}, label: {
            VStack {
                
                
                Image(systemName: "tag")
                //Text("Tags")
            }
        })
        .help("Tags")
    }
}
