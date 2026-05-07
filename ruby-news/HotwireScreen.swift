//
//  HotwireScreen.swift
//  ruby-news
//
//  Created by JEFF.DEAN on 5/7/26.
//

import HotwireNative
import SwiftUI
import UIKit

struct HotwireScreen: UIViewControllerRepresentable {
    let route: WebRoute

    func makeCoordinator() -> Coordinator {
        Coordinator(startURL: route.url())
    }

    func makeUIViewController(context: Context) -> UIViewController {
        context.coordinator.startIfNeeded()
        return context.coordinator.rootViewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.routeIfNeeded(to: route.url())
    }
}

extension HotwireScreen {
    final class Coordinator {
        private let navigator: Navigator
        private var currentURL: URL
        private var hasStarted = false

        var rootViewController: UIViewController {
            navigator.rootViewController
        }

        init(startURL: URL) {
            currentURL = startURL
            navigator = Navigator(configuration: .init(name: "main", startLocation: startURL))
            navigator.rootViewController.setNavigationBarHidden(true, animated: false)
            navigator.modalRootViewController.setNavigationBarHidden(true, animated: false)
        }

        func startIfNeeded() {
            guard !hasStarted else { return }

            hasStarted = true
            navigator.start()
        }

        func routeIfNeeded(to url: URL) {
            guard url != currentURL else { return }

            currentURL = url
            guard hasStarted else { return }

            navigator.clearAll(animated: false)
            navigator.route(url, options: VisitOptions(action: .replace))
        }
    }
}
