//
//  HotwireErrorMessageTests.swift
//  ruby-newsTests
//

import Foundation
import HotwireNative
import Testing
import WebKit
@testable import ruby_news

@Suite
struct HotwireErrorMessageTests {
    // MARK: Web errors

    @Test
    func offlineWebErrorShowsOfflineCopy() {
        let copy = HotwireErrorMessage(.web(WebError(urlError: URLError(.notConnectedToInternet))))
        #expect(copy.title == "인터넷 연결 끊김")
        #expect(copy.description == "네트워크 연결을 확인한 뒤 다시 시도해 주세요.")
    }

    @Test
    func timeoutWebErrorShowsTimeoutCopy() {
        let copy = HotwireErrorMessage(.web(WebError(urlError: URLError(.timedOut))))
        #expect(copy.title == "시간 초과")
        #expect(copy.description == "요청 시간이 초과되었습니다. 다시 시도해 주세요.")
    }

    @Test
    func connectionWebErrorShowsConnectionCopy() {
        let copy = HotwireErrorMessage(.web(WebError(urlError: URLError(.cannotConnectToHost))))
        #expect(copy.title == "서버에 연결할 수 없음")
        #expect(copy.description == "서버에 연결할 수 없습니다. 잠시 후 다시 시도해 주세요.")
    }

    @Test
    func otherWebErrorShowsGenericNetworkCopy() {
        let copy = HotwireErrorMessage(.web(WebError(errorCode: 999, message: "something else")))
        #expect(copy.title == "네트워크 오류")
        #expect(copy.description == "네트워크 오류가 발생했습니다. 다시 시도해 주세요.")
    }

    // MARK: HTTP errors

    @Test
    func notFoundShowsNotFoundCopy() {
        let copy = HotwireErrorMessage(.http(HTTPError(statusCode: 404)!))
        #expect(copy.title == "페이지를 찾을 수 없음")
        #expect(copy.description == "요청하신 페이지를 찾을 수 없습니다.")
    }

    @Test
    func unauthorizedShowsAccessDeniedCopy() {
        let copy = HotwireErrorMessage(.http(HTTPError(statusCode: 401)!))
        #expect(copy.title == "접근 권한 없음")
        #expect(copy.description == "이 페이지에 접근할 권한이 없습니다. 로그인 상태를 확인해 주세요.")
    }

    @Test
    func forbiddenShowsAccessDeniedCopy() {
        let copy = HotwireErrorMessage(.http(HTTPError(statusCode: 403)!))
        #expect(copy.title == "접근 권한 없음")
        #expect(copy.description == "이 페이지에 접근할 권한이 없습니다. 로그인 상태를 확인해 주세요.")
    }

    @Test
    func otherClientErrorShowsGenericRequestCopy() {
        let copy = HotwireErrorMessage(.http(HTTPError(statusCode: 422)!))
        #expect(copy.title == "요청 오류")
        #expect(copy.description == "요청을 처리할 수 없습니다. 잠시 후 다시 시도해 주세요.")
    }

    @Test
    func serverErrorShowsServerErrorCopy() {
        let copy = HotwireErrorMessage(.http(HTTPError(statusCode: 500)!))
        #expect(copy.title == "서버 오류")
        #expect(copy.description == "서버에 일시적인 문제가 있습니다. 잠시 후 다시 시도해 주세요.")
    }

    // MARK: Load errors

    @Test
    func loadErrorShowsLoadFailureCopy() {
        let copy = HotwireErrorMessage(.load(.notPresent))
        #expect(copy.title == "페이지를 불러올 수 없음")
        #expect(copy.description == "페이지를 불러오는 중 문제가 발생했습니다. 다시 시도해 주세요.")
    }
}