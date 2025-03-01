//
//  IconGallery.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/27/25.
//

import SwiftUI


struct IconContainer: View {
    var baseSymbol: String? = nil
    let overlaySymbol: String
    /// Scale factor for the overlay relative to the container’s size
    let overlayScale: CGFloat
    var baseColor: Color?
    var overlayColor: Color?

    var body: some View {
        GeometryReader { geometry in
            let containerSize = min(geometry.size.width, geometry.size.height)
            ZStack {
                if baseSymbol != nil {
                    
                    
                    Image(systemName: baseSymbol ?? "")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(baseColor)
                }
                Image(systemName: overlaySymbol)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(overlayScale * (containerSize / 50))
                    .foregroundColor(overlayColor)
              
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}





struct IconGallery_Previews: PreviewProvider {
    static var previews: some View {
        
        VStack {



            
            HStack {
                SpacedRepitionTimeframeIcon()
                TagIcon()

                DynamicIcon()
                EssentialIcon()
            }
       
            
            HStack {
                FlashCardIcon()
                PlainCardIcon()
            }
            
 

            HStack {
                SkipIcon(skipCount: 9)
                NextIcon()
                FlipIcon()

            }
        }
        
        

    }
}





