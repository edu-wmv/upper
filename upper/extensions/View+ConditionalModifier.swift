//
//  View+ConditionalModifier.swift
//  upper
//
//  Created by Eduardo Monteiro on 25/02/26.
//

import SwiftUI

extension View {
    @ViewBuilder func conditionalModifier<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
