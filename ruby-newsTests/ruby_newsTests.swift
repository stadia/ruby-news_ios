//
//  ruby_newsTests.swift
//  ruby-newsTests
//
//  Created by JEFF.DEAN on 5/6/26.
//

import Testing
@testable import ruby_news

struct ruby_newsTests {

    @Test func appTabsExposeInitialProductStructure() async throws {
        #expect(AppTab.allCases == [.news, .feed, .profile])
        #expect(AppTab.news.title == "뉴스")
        #expect(AppTab.feed.title == "피드")
        #expect(AppTab.profile.title == "내 정보")
    }

    @Test func appTabsExposeStableAccessibilityIdentifiers() async throws {
        #expect(AppTab.news.accessibilityIdentifier == "tab.news")
        #expect(AppTab.feed.accessibilityIdentifier == "tab.feed")
        #expect(AppTab.profile.accessibilityIdentifier == "tab.profile")
    }
}
