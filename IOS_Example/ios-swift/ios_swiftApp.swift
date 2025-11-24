//
//  ios_swiftApp.swift
//  ios-swift
//
//  Created by hypercloud on 11/21/25.
//

import SwiftUI

@main
struct ios_swiftApp: App {

    // AppDelegate 연결
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
