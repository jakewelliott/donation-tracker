//
//  ContentView.swift
//  DonationTracker
//
//  Created by Jake Elliott on 5/16/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tabs = .items
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Items", systemImage: "list.bullet", value: .items) {
                ItemsView()
            }
            Tab("Scan", systemImage: "barcode.viewfinder", value: .scan) {
                ScanView()
            }
            Tab("Settings", systemImage: "gearshape", value: .settings) {
                SettingsView()
            }

        }
        .tabViewStyle(.sidebarAdaptable)
    }
}

enum Tabs: Equatable, Hashable {
    case items
    case scan
    case settings
}

#Preview {
    ContentView()
}
