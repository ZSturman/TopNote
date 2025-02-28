//
//  Skip+SeenTableView.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/25/25.
//

import SwiftUI
struct SkipSeenTableView: View {
    let skipCount: Int
    let seenCount: Int
    
    var body: some View {
        List {
            Section(header: Text("Skip + Seen").font(.headline)) {
                HStack {
                    Text("Skip Count")
                    Spacer()
                    Text("\(skipCount)")
                }
                HStack {
                    Text("Seen Count")
                    Spacer()
                    Text("\(seenCount)")
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

struct SkipSeenTableView_Previews: PreviewProvider {
    static var previews: some View {
        SkipSeenTableView(skipCount: 3, seenCount: 10)
            .previewLayout(.sizeThatFits)
    }
}
