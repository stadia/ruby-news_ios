//
//  AppEnvironment.swift
//  ruby-news
//
//  Created by JEFF.DEAN on 5/7/26.
//

import Foundation

enum AppEnvironment {
    #if DEBUG && targetEnvironment(simulator)
    static let baseURL = URL(string: "http://localhost:3000")!
    #else
    static let baseURL = URL(string: "https://ruby-news.kr")!
    #endif
}
