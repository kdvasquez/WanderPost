
//
//  TabRouter.swift
//  PostcardApp
//

import SwiftUI

class TabRouter: ObservableObject {
    @Published var currentTab: Int = 0
}

// MARK: - Environment Key for resetting navigation to home

private struct ResetToHomeKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var resetToHome: () -> Void {
        get { self[ResetToHomeKey.self] }
        set { self[ResetToHomeKey.self] = newValue }
    }
}

// MARK: - Environment Key for navPath binding

private struct NavPathKey: EnvironmentKey {
    static let defaultValue: Binding<[AppRoute]> = .constant([])
}

extension EnvironmentValues {
    var navPath: Binding<[AppRoute]> {
        get { self[NavPathKey.self] }
        set { self[NavPathKey.self] = newValue }
    }
}
