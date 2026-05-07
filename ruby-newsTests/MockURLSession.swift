//
//  MockURLProtocol.swift
//  ruby-newsTests
//

import Foundation

class MockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) -> (HTTPURLResponse, Data?))?
    static var routeHandler: ((URLRequest) -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        // Route handler takes priority (can dispatch by URL)
        if let routeHandler = Self.routeHandler {
            let (response, data) = routeHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data { client?.urlProtocol(self, didLoad: data) }
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        guard let handler = Self.handler else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if let data { client?.urlProtocol(self, didLoad: data) }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    static func reset() {
        handler = nil
        routeHandler = nil
    }
}

extension URLSession {
    static func mockSession(handler: @escaping (URLRequest) -> (HTTPURLResponse, Data?)) -> URLSession {
        MockURLProtocol.handler = handler
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    static func mockSession(responseData: Data, statusCode: Int) -> URLSession {
        mockSession { _ in
            (
                HTTPURLResponse(url: URL(string: "http://localhost:3000/mock")!, statusCode: statusCode, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                responseData
            )
        }
    }

    /// Route-based mock that dispatches based on the request URL path.
    /// This avoids global handler conflicts when tests run in parallel.
    static func routingMockSession(routes: [(path: String, statusCode: Int, data: Data)]) -> URLSession {
        MockURLProtocol.routeHandler = { request in
            let path = request.url?.path ?? ""
            for route in routes {
                if path.contains(route.path) {
                    return (
                        HTTPURLResponse(url: request.url!, statusCode: route.statusCode, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                        route.data
                    )
                }
            }
            return (
                HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                Data("not found".utf8)
            )
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}