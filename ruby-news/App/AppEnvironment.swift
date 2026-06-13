//
//  AppEnvironment.swift
//  ruby-news
//
//  Created by JEFF.DEAN on 5/7/26.
//

import Foundation

enum AppEnvironment {
    static let productionBaseURL = URL(string: "https://ruby-news.dev")!

    #if DEBUG && targetEnvironment(simulator)
    static let baseURL = URL(string: "http://localhost:3000")!
    #else
    static let baseURL = productionBaseURL
    #endif
}
