//
//  FlashcardWidgetView.swift
//  TopNoteWidgetExtension
//
//  Created by Zachary Sturman on 2/25/25.
//

import Foundation
import SwiftUI
import SwiftData
import WidgetKit

struct FlashCardWidgetView: View {
    @Environment(\.widgetFamily) var family
    let skipCount: Int = 0
    let front: String
    let back: String
    let isCardFlipped: Bool
    let isEssential: Bool
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    if isCardFlipped {
                        Text(front)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .truncationMode(.tail)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal)
                        
                        Text(back)
                            .font(.footnote)
                            //.multilineTextAlignment(.center)
                            .truncationMode(.tail)
                            .lineLimit(nil)
                            .minimumScaleFactor(0.8)
                    } else {
                        Text(front)
                            .font(.footnote) // or use a custom font approach
                            .bold()
                            .multilineTextAlignment(.center)
                            .truncationMode(.tail)
                            .lineLimit(nil)
                            .minimumScaleFactor(0.8)
                    }
                }
                .frame(height: geo.size.height * 0.7) // allocate ~70% of height
                .frame(maxWidth: .infinity)
                
                Spacer(minLength: 0)
                
                // Bottom portion for buttons or ratings (the remaining ~30%)
                if isCardFlipped {
                    selectRatings()
                } else {
                    bottomButtonRow()
                }
            }
            
        }
    }
    
    // MARK: - Bottom Buttons (Not Flipped)
    @ViewBuilder
    private func bottomButtonRow() -> some View {
        if family == .systemSmall {
            HStack {
                Button(intent: ArchiveCardIntent(), label: {
                    VStack {
                        ArchiveIcon(iconSize: 2.5)
                        
                        
                        
                    }
                    .font(.footnote)
                })
                .buttonStyle(.bordered)
                
                .buttonBorderShape(.circle)
                
                
                Button(intent: ShowFlashcardBackIntent()) {
                    VStack {
                        
                        FlipIcon(removeBorder: true, iconSize: 3)
                        
                    }
                    .font(.footnote)
                    
                    
                }
                .buttonStyle(.bordered)
                
                .buttonBorderShape(.circle)
                
                if isEssential {
                    Button(intent: SkipCardIntent()) {

                            
                            
                            SkipIcon(skipCount: skipCount, removeBorder: true, removePaddingAndExtraFontSize: true, iconSize: 3.5)
                        
                        
                    }
                    
                    .buttonStyle(.bordered)
                    
                    .buttonBorderShape(.circle)
                } else {
                    Button(intent: NextCardIntent()) {
                        NextIcon( removeBorder: true, iconSize: 3)
                    }
                    
                    .buttonStyle(.bordered)
                    
                    .buttonBorderShape(.circle)
                }
            }
        } else {
            HStack {
                Button(intent: ArchiveCardIntent(), label: {
                    HStack {
                        Image(systemName: "archivebox")
                    }
                    .font(.footnote)
                })
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                
                
                
                
                Button(intent: ShowFlashcardBackIntent()) {
                    HStack {
                        Spacer()
                        Image(systemName: "rectangle.2.swap")
                        Text("Flip")
                        Spacer()
                    }
                    .font(.footnote)
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                if isEssential {
                    Button(intent: SkipCardIntent()) {
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.trianglehead.counterclockwise.rotate.90")
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
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Ratings (Flipped)
    @ViewBuilder
    private func selectRatings() -> some View {
        switch family {
        case .systemSmall:
            HStack {
                ForEach(Array(RatingType.allCases.enumerated()), id: \.offset) { index, rating in
                    Button(intent: SubmitFlashcardRatingTypeIntent(selectedRating: index)) {
                        Image(systemName: rating.systemImage)
                            .font(.caption)
                    }
                    .buttonBorderShape(.circle)
                }
            }
        case .systemMedium:
            
            HStack{
                ForEach(Array(RatingType.allCases.enumerated()), id: \.offset) { index, rating in
                    Button(intent: SubmitFlashcardRatingTypeIntent(selectedRating: index)) {
                        HStack {
                            Image(systemName: rating.systemImage)
                            Text(rating.rawValue)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .font(.caption)
                }
            }
        case .systemLarge:
            HStack(spacing: 8) {
                ForEach(Array(RatingType.allCases.enumerated()), id: \.offset) { index, rating in
                    Button(intent: SubmitFlashcardRatingTypeIntent(selectedRating: index)) {
                        Text(rating.rawValue)
                            .font(.caption)
                    }
                }
            }
        case .systemExtraLarge:
            HStack(spacing: 8) {
                ForEach(Array(RatingType.allCases.enumerated()), id: \.offset) { index, rating in
                    Button(intent: SubmitFlashcardRatingTypeIntent(selectedRating: index)) {
                        Image(systemName: rating.systemImage)
                            .font(.caption)
                    }
                }
            }
        default:
            Text("Some other family: \(family)")
        }
    }
}


// MARK: - Preview

struct FlashCardWidgetView_Previews: PreviewProvider {
    static let front: String = "What is the capital of France? There's extra stuff here so we can see how it looks with an even longer bit of text"
    static let back: String = "Paris. This is also a good deal longer because the back of the card could potentially be pretty long too"
    
    static var previews: some View {
        Group {
            
            
            // Small widget preview (Not Flipped)
            FlashCardWidgetView(
                front: front,
                back: back,
                isCardFlipped: false,
                isEssential: false
            )
            .containerBackground(.fill.tertiary, for: .widget)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Flashcard - Small - Not Flipped - Non Essential")
            
            // Small widget preview (Not Flipped)
            FlashCardWidgetView(
                front: front,
                back: back,
                isCardFlipped: false,
                isEssential: true
            )
            .containerBackground(.fill.tertiary, for: .widget)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Flashcard - Small - Not Flipped - Essential")
            
            // Small widget preview (Flipped)
            FlashCardWidgetView(
                front: front,
                back: back,
                isCardFlipped: true,
                isEssential: true
            )
            .containerBackground(.fill.tertiary, for: .widget)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Flashcard - Small - Flipped")
            
            
            
            
            // Medium widget preview (Not Flipped)
            FlashCardWidgetView(
                front: front,
                back: back,
                isCardFlipped: false,
                isEssential: false
            )
            .containerBackground(.fill.tertiary, for: .widget)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Flashcard - Medium - Not Flipped - Non Essential")
            
            // Medium widget preview (Not Flipped)
            FlashCardWidgetView(
                front: front,
                back: back,
                isCardFlipped: false,
                isEssential: true
            )
            .containerBackground(.fill.tertiary, for: .widget)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Flashcard - Medium - Not Flipped - Non Essential")
            
            // Medium widget preview (Flipped)
            FlashCardWidgetView(
                front: front,
                back: back,
                isCardFlipped: true,
                isEssential: true
            )
            .containerBackground(.fill.tertiary, for: .widget)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Flashcard - Medium - Flipped")
            
            
            
        }
    }
}
