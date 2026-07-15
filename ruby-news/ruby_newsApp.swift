//
//  ruby_newsApp.swift
//  ruby-news
//
//  Created by JEFF.DEAN on 5/6/26.
//

import HotwireNative
import SwiftUI

@main
struct RubyNewsApp: App {
    init() {
        Hotwire.config.defaultNavigationController = { SheetSafeHotwireNavigationController() }
        WebSessionBridge().restorePersistedCookiesToSharedStorage()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(.rnBrand)
        }
    }
}
