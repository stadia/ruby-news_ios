//
//  HotwireErrorMessage.swift
//  ruby-news
//

import Foundation
import HotwireNative

/// `HotwireNativeError`를 한국어 안내문(title + description)으로 매핑.
/// SwiftUI 에러 뷰(`RubyNewsErrorView`)가 사용하며, 순수 매핑 로직만 분리해 단위 테스트 대상.
struct HotwireErrorMessage {
    let title: String
    let description: String

    init(_ error: HotwireNativeError) {
        switch error {
        case .web(let webError):
            if webError.isOffline {
                title = "인터넷 연결 끊김"
                description = "네트워크 연결을 확인한 뒤 다시 시도해 주세요."
            } else if webError.isTimeout {
                title = "시간 초과"
                description = "요청 시간이 초과되었습니다. 다시 시도해 주세요."
            } else if webError.isConnectionError {
                title = "서버에 연결할 수 없음"
                description = "서버에 연결할 수 없습니다. 잠시 후 다시 시도해 주세요."
            } else {
                title = "네트워크 오류"
                description = "네트워크 오류가 발생했습니다. 다시 시도해 주세요."
            }
        case .http(let httpError):
            switch httpError {
            case .client(let clientError):
                switch clientError {
                case .notFound:
                    title = "페이지를 찾을 수 없음"
                    description = "요청하신 페이지를 찾을 수 없습니다."
                case .unauthorized, .forbidden:
                    title = "접근 권한 없음"
                    description = "이 페이지에 접근할 권한이 없습니다. 로그인 상태를 확인해 주세요."
                default:
                    title = "요청 오류"
                    description = "요청을 처리할 수 없습니다. 잠시 후 다시 시도해 주세요."
                }
            case .server:
                title = "서버 오류"
                description = "서버에 일시적인 문제가 있습니다. 잠시 후 다시 시도해 주세요."
            }
        case .load:
            title = "페이지를 불러올 수 없음"
            description = "페이지를 불러오는 중 문제가 발생했습니다. 다시 시도해 주세요."
        }
    }
}