import Testing
import WebKit
@testable import ruby_news

struct HotwireNavigationErrorPolicyTests {
    @Test
    func frameLoadInterruptionIsNotPresented() {
        let error = NSError(
            domain: WKError.errorDomain,
            code: 102
        )
        #expect(!HotwireNavigationErrorPolicy.shouldPresent(error))
    }

    @Test
    func legacyDomainFrameLoadInterruptionIsNotPresented() {
        let error = NSError(
            domain: "WebKitErrorDomain",
            code: 102
        )
        #expect(!HotwireNavigationErrorPolicy.shouldPresent(error))
    }

    @Test
    func otherWKErrorsArePresented() {
        let error = NSError(
            domain: WKError.errorDomain,
            code: WKError.Code.webContentProcessTerminated.rawValue
        )
        #expect(HotwireNavigationErrorPolicy.shouldPresent(error))
    }

    @Test
    func unrelatedErrorsArePresented() {
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet
        )
        #expect(HotwireNavigationErrorPolicy.shouldPresent(error))
    }
}
