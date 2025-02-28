//
//  SeenTableView.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/25/25.
//


import SwiftUI
struct SeenTableView: View {
    let seenCount: Int
    
    var body: some View {
        List {
            Section(header: Text("Seen").font(.headline)) {
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

struct SeenTableView_Previews: PreviewProvider {
    static var previews: some View {
        SeenTableView(seenCount: 10)
            .previewLayout(.sizeThatFits)
    }
}
