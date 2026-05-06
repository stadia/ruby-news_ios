//
//  AppTab.swift
//  ruby-news
//
//  Created by JEFF.DEAN on 5/6/26.
//

import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case news
    case feed
    case profile

    var id: Self { self }

    var title: String {
        switch self {
        case .news:
            return "뉴스"
        case .feed:
            return "피드"
        case .profile:
            return "내 정보"
        }
    }

    var systemImage: String {
        switch self {
        case .news:
            return "newspaper"
        case .feed:
            return "person.2"
        case .profile:
            return "person.crop.circle"
        }
    }

    var accessibilityIdentifier: String {
        "tab.\(rawValue)"
    }
}
