////
////  ImageLoadFailedPlaceholder.swift
////  TopNote
////
////  Created by Zachary Sturman on 12/15/25.
////
//
//// MARK: - IMAGE DISABLED
//// This file is kept for API compatibility but is no longer used.
//// The Card model schema is preserved for production compatibility.
//
//import SwiftUI
//import WidgetKit
//
///// Placeholder view shown when a card has an image but it couldn't be loaded in the widget
///// IMAGE DISABLED: This view is no longer displayed since image functionality is disabled
//struct ImageLoadFailedPlaceholder: View {
//    let cardType: CardType
//    @Environment(\.widgetFamily) private var widgetFamily
//    
//    var body: some View {
//        ZStack {
//            // Gradient background matching card type
//            LinearGradient(
//                colors: [
//                    cardType.tintColor.opacity(0.3),
//                    cardType.tintColor.opacity(0.15)
//                ],
//                startPoint: .topLeading,
//                endPoint: .bottomTrailing
//            )
//            
//            VStack(spacing: isCompact ? 6 : 10) {
//                Image(systemName: "photo.badge.exclamationmark")
//                    .font(isCompact ? .title2 : .title)
//                    .foregroundColor(.secondary)
//                
//                if !isCompact {
//                    Text("Open app to view image")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                        .multilineTextAlignment(.center)
//                        .padding(.horizontal, 8)
//                }
//            }
//        }
//    }
//    
//    private var isCompact: Bool {
//        widgetFamily == .systemSmall || widgetFamily == .systemMedium
//    }
//}
//
//#if DEBUG
//struct ImageLoadFailedPlaceholder_Previews: PreviewProvider {
//    static var previews: some View {
//        ImageLoadFailedPlaceholder(cardType: .flashcard)
//            .frame(width: 300, height: 200)
//            .previewDisplayName("Medium")
//        
//        ImageLoadFailedPlaceholder(cardType: .note)
//            .frame(width: 155, height: 155)
//            .previewDisplayName("Small")
//    }
//}
//#endif
