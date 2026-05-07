//
//  CurrentUser.swift
//  ruby-news
//

import Foundation

struct CurrentUser: Decodable, Identifiable, Equatable {
    let id: Int
    let email: String
    let name: String
    let username: String
    let avatarURL: URL?

    var profileURL: URL {
        URL(string: "/@\(username)", relativeTo: AppEnvironment.baseURL)!
    }

    enum CodingKeys: String, CodingKey {
        case id, email, name, username
        case avatarURL = "avatarUrl"
    }
}

struct AccountResponse: Decodable {
    let user: CurrentUser
}