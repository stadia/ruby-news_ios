//
//  ruby_newsApp.swift
//  ruby-news
//
//  Created by JEFF.DEAN on 5/6/26.
//

import HotwireNative
import SwiftUI
import WebKit

@main
struct ruby_newsApp: App {
    init() {
        WebSessionBridge().restorePersistedCookiesToSharedStorage()
        configureHotwire()
    }

    private func configureHotwire() {
        Hotwire.config.makeCustomWebView = { configuration in
            let webView = WKWebView(frame: .zero, configuration: configuration)
            #if DEBUG
            if #available(iOS 16.4, *) {
                webView.isInspectable = true
            }
            #endif
            return webView
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(.rnBrand)
        }
    }
}
