//
//  SkipIcon.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/27/25.
//

import Foundation
import SwiftUI

import SwiftUI

struct SkipIcon: View {
    var skipCount: Int
    var removeBorder: Bool = false
    
        var numberPaddingAmount: CGFloat {
            if skipCount < 10 {
                return 3
            } else if skipCount < 100 {
                return 4
            } else {
                return 5
            }
        }
    
    var numberFontSize: CGFloat {
        if skipCount < 10 {
            return 17
        } else if skipCount < 100 {
            return 14
        } else {
            return 9
        }
    }

    var body: some View {
        
        ZStack {
            // Reuse IconContainer so it matches style/size
            
            if removeBorder {
                IconContainer(
                    baseSymbol: "",  // or another shape if you prefer
                    overlaySymbol: "arrow.trianglehead.counterclockwise.rotate.90",
                    overlayScale: 1.3
                )
            } else {
                
                
                IconContainer(
                    baseSymbol: "rectangle",  // or another shape if you prefer
                    overlaySymbol: "arrow.trianglehead.counterclockwise.rotate.90",
                    overlayScale: 0.55
                )
                
            }

            // Overlay the skip count text
            Text("\(skipCount)")
                .font(.system(size: numberFontSize, weight: .bold))
                .foregroundColor(.primary)
                .padding(.leading, numberPaddingAmount)
        }
     
    }
}
