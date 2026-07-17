//
//  RubyNewsErrorView.swift
//  ruby-news
//

import HotwireNative
import SwiftUI

/// HotwireNative 1.3+가 웹 방문 실패 시 보여줄 한국어 에러 화면.
/// 기본 영어 에러 뷰(`DefaultErrorView`)를 대체하며, 앱의 다른 에러/빈 상태
/// (`ContentUnavailableView` + "다시 시도") UI와 일관된 모양을 제공한다.
struct RubyNewsErrorView: ErrorPresentableView {
    let error: HotwireNativeError
    let handler: ErrorPresenter.Handler?

    var body: some View {
        let message = HotwireErrorMessage(error)
        ContentUnavailableView {
            Label(message.title, systemImage: "exclamationmark.triangle")
        } description: {
            Text(message.description)
        } actions: {
            if let handler {
                Button("다시 시도") { handler() }
            }
        }
        .tint(.rnBrand)
    }
}

#Preview("오프라인") {
    RubyNewsErrorView(error: .web(WebError(urlError: URLError(.notConnectedToInternet))), handler: {})
}

#Preview("서버 오류") {
    RubyNewsErrorView(error: .http(HTTPError(statusCode: 500) ?? .server(.internalServerError)), handler: {})
}

#Preview("페이지를 찾을 수 없음") {
    RubyNewsErrorView(error: .http(HTTPError(statusCode: 404) ?? .client(.notFound)), handler: nil)
}
