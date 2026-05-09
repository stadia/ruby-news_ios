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
            let preventZoomScript = """
            (function() {
                function disableZoom() {
                    var viewport = document.querySelector('meta[name="viewport"]');
                    if (viewport) {
                        var content = viewport.getAttribute('content');
                        if (!/user-scalable/i.test(content)) {
                            viewport.setAttribute('content', content + ', user-scalable=no, maximum-scale=1.0');
                        }
                    } else {
                        var meta = document.createElement('meta');
                        meta.name = 'viewport';
                        meta.content = 'width=device-width, initial-scale=1.0, user-scalable=no, maximum-scale=1.0';
                        if (document.head) document.head.appendChild(meta);
                    }
                }
                if (document.readyState === 'loading') {
                    document.addEventListener('DOMContentLoaded', disableZoom);
                } else {
                    disableZoom();
                }
            })();
            """
            configuration.userContentController.addUserScript(
                WKUserScript(source: preventZoomScript, injectionTime: .atDocumentStart, forMainFrameOnly: true)
            )

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
