//
//  String+Extensions.swift
//  upper
//
//  Created by Eduardo Monteiro on 16/03/26.
//

import SwiftUI

extension String {    
    func stringSize(usingFont font: Font) -> CGSize {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return CGSize(width: size.width, height: size.height)
    }
}
