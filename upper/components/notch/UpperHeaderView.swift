//
//  UpperHeaderView.swift
//  upper
//
//  Created by Eduardo Monteiro on 25/02/26.
//

import SwiftUI
import Defaults

struct UpperHeaderView: View {
    @EnvironmentObject var viewModel: UpperViewModel
    @ObservedObject var coordinator: UpperViewCoordinator = .shared
    
    var body: some View {
        HStack(spacing: 0) {
            if !Defaults[.enableMinimalMode] {
                HStack {}
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(viewModel.state == .closed ? 0 : 1)
                    .blur(radius: viewModel.state == .closed ? 20 : 0)
                    .animation(.smooth.delay(0.1), value: viewModel.state)
                    .zIndex(2)
            }
            
            if viewModel.state == .open && !Defaults[.enableMinimalMode] {
                Rectangle()
                    .fill(NSScreen.screens.first(where: {
                        $0.localizedName == coordinator.selectedScreen })?.safeAreaInsets.top ?? 0 > 0
                          ? .black
                          : .clear
                    )
                    .frame(width: viewModel.closedNotchSize.width)
                    .mask { NotchShape() }
            }
        }
        .foregroundStyle(.gray)
        .environmentObject(viewModel)
    }
}
