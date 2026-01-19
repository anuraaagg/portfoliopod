//
//  ContentView.swift
//  portfoliopod
//
//  Main content view - iPod device
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        DeviceShellView()
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
