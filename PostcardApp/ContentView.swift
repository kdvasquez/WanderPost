//
//  ContentView.swift
//  PostcardApp — WanderPost
//

import SwiftUI

enum AppRoute: Hashable, Equatable {
    case photoPicker
    case editor(Postcard?)
    case saveShare(UUID)

    static func == (lhs: AppRoute, rhs: AppRoute) -> Bool {
        switch (lhs, rhs) {
        case (.photoPicker, .photoPicker): return true
        case (.editor(let a), .editor(let b)): return a?.id == b?.id
        case (.saveShare(let a), .saveShare(let b)): return a == b
        default: return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .photoPicker:
            hasher.combine(0)
        case .editor(let p):
            hasher.combine(1)
            hasher.combine(p?.id)
        case .saveShare(let id):
            hasher.combine(2)
            hasher.combine(id)
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = PostcardViewModel()
    @StateObject private var locationManager = CoreLocationManager()
    @StateObject private var weatherManager = WeatherManager()
    @StateObject private var tabRouter = TabRouter()

    @State private var navPath: [AppRoute] = []

    var body: some View {
        TabView(selection: $tabRouter.currentTab) {

            NavigationStack(path: $navPath) {
                HomePage()
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .photoPicker:
                            PhotoPickerPage()
                        case .editor(let postcard):
                            EditorPage(postcard: postcard)
                        case .saveShare(let id):
                            SaveSharePage(postcardID: id)
                        }
                    }
            }
            .tabItem { Label("Postcards", systemImage: "photo.stack") }
            .tag(0)

            NavigationStack {
                StampsPage()
            }
            .tabItem { Label("Map", systemImage: "map") }
            .tag(1)
        }
        .environmentObject(viewModel)
        .environmentObject(locationManager)
        .environmentObject(weatherManager)
        .environmentObject(tabRouter)
        .environment(\.navPath, $navPath)
        .environment(\.resetToHome) {
            tabRouter.currentTab = 0
            DispatchQueue.main.async {
                navPath.removeAll()
            }
        }
        .tint(Color("AccentTan"))
    }
}
