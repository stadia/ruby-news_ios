//
//  ruby_newsApp.swift
//  ruby-news
//
//  Created by JEFF.DEAN on 5/6/26.
//

import SwiftUI

@main
struct ruby_newsApp: App {
    init() {
        WebSessionBridge().restorePersistedCookiesToSharedStorage()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
