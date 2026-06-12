//
//  HotwireScreen.swift
//  ruby-news
//
//  Created by JEFF.DEAN on 5/7/26.
//

import HotwireNative
import SwiftUI
import UIKit
import WebKit

enum HotwireNavigationErrorPolicy {
    /// WKWebView returns `frameLoadInterruptedByPolicyChange` (code 102)
    /// under the legacy `WebKitErrorDomain`, not `WKErrorDomain`.
    private static let frameLoadInterruptedByPolicyChangeCode = 102
    private static let ignoredDomains: Set<String> = [
        WKError.errorDomain,
        "WebKitErrorDomain",
    ]

    static func shouldPresent(_ error: Error) -> Bool {
        let error = error as NSError
        if ignoredDomains.contains(error.domain),
           error.code == frameLoadInterruptedByPolicyChangeCode {
            return false
        }
        return true
    }
}

struct HotwireScreen: UIViewControllerRepresentable {
    let route: WebRoute
    @Environment(\.colorScheme) private var colorScheme

    func makeCoordinator() -> Coordinator {
        Coordinator(startURL: route.url())
    }

    func makeUIViewController(context: Context) -> UIViewController {
        context.coordinator.startIfNeeded()
        return context.coordinator.rootViewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        uiViewController.overrideUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        context.coordinator.routeIfNeeded(to: route.url())
    }
}

extension HotwireScreen {
    @MainActor
    final class Coordinator {
        private let navigatorDelegate: NavigatorAuthDelegate
        private let navigator: Navigator
        private let webSessionBridge: WebSessionBridge
        private var sessionChangeObserver: NSObjectProtocol?
        private var currentURL: URL
        private var hasStarted = false

        var rootViewController: UIViewController {
            navigator.rootViewController
        }

        init(startURL: URL) {
            currentURL = startURL
            webSessionBridge = WebSessionBridge(baseURL: startURL)
            navigatorDelegate = NavigatorAuthDelegate(
                monitor: WebAuthEventMonitor(
                    baseURL: startURL,
                    handleExternalLogout: {
                        await SessionStore.handleExternalLogout()
                    }
                )
            )
            navigator = Navigator(configuration: .init(name: "main", startLocation: startURL), delegate: navigatorDelegate)
            navigator.rootViewController.setNavigationBarHidden(true, animated: false)
            navigator.modalRootViewController.setNavigationBarHidden(true, animated: false)
            sessionChangeObserver = NotificationCenter.default.addObserver(
                forName: WebSessionBridge.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.reloadForSessionChange()
                }
            }
        }

        deinit {
            if let sessionChangeObserver {
                NotificationCenter.default.removeObserver(sessionChangeObserver)
            }
        }

        func startIfNeeded() {
            guard !hasStarted else { return }

            hasStarted = true
            Task { @MainActor in
                await webSessionBridge.syncSharedCookiesToWebView()
                navigator.start()
            }
        }

        func routeIfNeeded(to url: URL) {
            guard url != currentURL else { return }

            currentURL = url
            guard hasStarted else { return }

            navigator.clearAll(animated: false)
            navigator.route(url, options: VisitOptions(action: .replace))
        }

        private func reloadForSessionChange() {
            Task { @MainActor in
                await webSessionBridge.syncSharedCookiesToWebView()
                guard hasStarted else { return }
                navigator.reload()
            }
        }
    }

    final class NavigatorAuthDelegate: NSObject, NavigatorDelegate {
        private let monitor: WebAuthEventMonitor

        init(monitor: WebAuthEventMonitor) {
            self.monitor = monitor
        }

        func requestDidFinish(at url: URL) {
            monitor.requestDidFinish(at: url)
        }

        func formSubmissionDidFinish(at url: URL) {
            monitor.formSubmissionDidFinish(at: url)
        }

        func visitableDidFailRequest(
            _ visitable: Visitable,
            error: Error,
            retryHandler: RetryBlock?
        ) {
            guard HotwireNavigationErrorPolicy.shouldPresent(error),
                  let errorPresenter = visitable as? ErrorPresenter else {
                return
            }

            errorPresenter.presentError(error, retryHandler: retryHandler)
        }
    }
}
