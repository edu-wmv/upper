//
//  UpperHomeView.swift
//  upper
//
//  Created by Eduardo Monteiro on 25/02/26.
//

import SwiftUI
import Defaults

struct UpperHomeView: View {
    @EnvironmentObject var viewModel: UpperViewModel
    @ObservedObject var coordinator: UpperViewCoordinator = .shared
    
    var body: some View {
        Group {
            if !coordinator.firstLaunch {
                mainContent
            }
        }
        .transition(.opacity.combined(with: .blurReplace))
    }
    
    private var mainContent: some View {
        HStack(alignment: .top, spacing: 20) {
            if Defaults[.enableMinimalMode] {
                MinimalMediaView()
            } else {
                Text("Welcome to Upper")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .background(.red)
        .transition(.opacity.animation(.smooth.speed(0.9))
            .combined(with: .blurReplace.animation(.smooth.speed(0.9)))
            .combined(with: .move(edge: .top))
        )
        .blur(radius: viewModel.state == .closed ? 30 : 0)
        
    }
}
