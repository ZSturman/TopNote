//
//  NoCardTypeWidgetView.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/25/25.
//

import Foundation
import SwiftUI
import WidgetKit

struct NoCardTypeWidgetView: View {
    @Environment(\.widgetFamily) var family
    let content: String
    
    let isEssential: Bool
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                // Top portion for text (about 70% of total height)
                VStack(spacing: 4) {
                    formattedContentView(from: content)
                                           .font(.subheadline)
                                           .multilineTextAlignment(.center)
                                           .truncationMode(.tail)
                                           .minimumScaleFactor(0.7)
                }
                .frame(height: geo.size.height * 0.7) // allocate ~70% of height
                .frame(maxWidth: .infinity)
                
                Spacer(minLength: 0)
                
                HStack {
                    
                    
                    if family == .systemSmall {
                        Button(intent: ArchiveCardIntent(), label: {
                            VStack {
                                Image(systemName: "archivebox")
                                
                            }
                            .font(.footnote)
                        })
                        .buttonStyle(.bordered)
                        
                        .buttonBorderShape(.circle)
                        
                        if isEssential {
                            Button(intent: SkipCardIntent()) {
                                Image(systemName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90")
                                
                                Text("Skip")
                            }
                            .font(.footnote)
                            .buttonStyle(.bordered)
                        
                            
                            
                        } else {
                            Button(intent: NextCardIntent()) {
                                Image(systemName: "checkmark.rectangle.stack")
                                Text("Next")
                                
                            }
                            .font(.footnote)
                            .buttonStyle(.bordered)
                            
                            
                        }
                    } else {
                        Button(intent: ArchiveCardIntent(), label: {
                            HStack {
                                Spacer()
                                Image(systemName: "archivebox")
                                Text("Archive")
                                Spacer()
                            }
                            .font(.footnote)
                        })
                        .buttonStyle(.bordered)
                        
                        if isEssential {
                            Button(intent: SkipCardIntent()) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90")
                                    Text("Skip")
                                    Spacer()
                                }
                                .font(.footnote)
                            }
                            .buttonStyle(.bordered)
                            
                            
                        } else {
                            Button(intent: NextCardIntent()) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "checkmark.rectangle.stack")
                                    Text("Next")
                                    Spacer()
                                }
                                .font(.footnote)
                                
                            }
                            .buttonStyle(.bordered)
                            
                        }
                        
                    }
                    //WidgetSkipOrNextButton(isEssential: isEssential)
                }
            }
            
            
            
        }
    }
    
    
    @ViewBuilder
    private func formattedContentView(from text: String) -> some View {
        let components = splitTextByURLs(text)
        
        HStack(spacing: 0) {
            ForEach(components, id: \.self) { component in
                if let url = URL(string: component), component.starts(with: "http") {
                    Link(destination: url) {
                        Text(component)
                            .foregroundColor(.blue)
                            .underline()
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                } else {
                    Text(component)
                }
            }
        }
    }

    /// Splits text into regular text components and URLs separately
    private func splitTextByURLs(_ text: String) -> [String] {
        let urlRegex = try! NSRegularExpression(
            pattern: #"(https?|ftp|file|mailto):\/\/[^\s/$.?#].[^\s]*|www\.[^\s/$.?#].[^\s]*|[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(\/\S*)?"#,
            options: []
        )

        let matches = urlRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        var result: [String] = []
        var lastIndex = text.startIndex
        
        for match in matches {
            if let range = Range(match.range, in: text) {
                let beforeText = String(text[lastIndex..<range.lowerBound])
                if !beforeText.isEmpty {
                    result.append(beforeText)
                }
                
                let urlString = String(text[range])
                let formattedURL = urlString.hasPrefix("http") ? urlString : "https://" + urlString
                result.append(formattedURL)
                
                lastIndex = range.upperBound
            }
        }
        
        let remainingText = String(text[lastIndex..<text.endIndex])
        if !remainingText.isEmpty {
            result.append(remainingText)
        }
        
        return result
    }
    

    
}

struct NoCardTypeWidgetView_Previews: PreviewProvider {
    
    static var previews: some View {
        let content: String =  "Here's a quote you might like to see every once in a while. There's some length so we can see how it looks trucated on smaller widget sizes."
        
        Group {
            // Small widget preview
            NoCardTypeWidgetView(content: content, isEssential: false)
                .containerBackground(.fill.tertiary, for: .widget)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("No Type - Small - Non Essential")
            
            NoCardTypeWidgetView(content: content, isEssential: true)
                .containerBackground(.fill.tertiary, for: .widget)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("No Type - Small - Essential")
            
            
            NoCardTypeWidgetView(content: content, isEssential: false)
                .containerBackground(.fill.tertiary, for: .widget)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("No Type - Medium - Non Essential")
            
            NoCardTypeWidgetView(content: content, isEssential: true)
                .containerBackground(.fill.tertiary, for: .widget)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("No Type - Medium - Essential")
            
        }
    }
}
