//
//  MockURLSession.swift
//  ruby-newsTests
//

import Foundation
import Mocker

/// 세션별 고유 ID를 헤더로 주입해 핸들러를 격리한다.
/// 병렬 테스트가 정적 핸들러를 덮어쓰는 문제를 막기 위한 장치다.
private final class MockHandlerRegistry: @unchecked Sendable {
    static let shared = MockHandlerRegistry()
    private let lock = NSLock()
    private var handlers: [String: (URLRequest) -> (HTTPURLResponse, Data?)] = [:]

    func register(_ handler: @escaping (URLRequest) -> (HTTPURLResponse, Data?), forSessionID id: String) {
        lock.lock(); defer { lock.unlock() }
        handlers[id] = handler
    }

    func handler(forSessionID id: String) -> ((URLRequest) -> (HTTPURLResponse, Data?))? {
        lock.lock(); defer { lock.unlock() }
        return handlers[id]
    }
}

final class MockURLProtocol: URLProtocol {
    static let sessionIDHeader = "X-Mock-Session-ID"

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let id = request.value(forHTTPHeaderField: Self.sessionIDHeader) ?? ""
        guard let handler = MockHandlerRegistry.shared.handler(forSessionID: id) else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if let data { client?.urlProtocol(self, didLoad: data) }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

extension URLSession {
    /// 동적 응답이 필요한 테스트용. 세션마다 격리된 핸들러를 등록한다.
    static func mockSession(handler: @escaping (URLRequest) -> (HTTPURLResponse, Data?)) -> URLSession {
        let sessionID = UUID().uuidString
        MockHandlerRegistry.shared.register(handler, forSessionID: sessionID)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        config.httpAdditionalHeaders = [MockURLProtocol.sessionIDHeader: sessionID]
        return URLSession(configuration: config)
    }

    /// 고정 응답 케이스용. Mocker 기반.
    static func mockerSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockingURLProtocol.self]
        return URLSession(configuration: config)
    }
}
