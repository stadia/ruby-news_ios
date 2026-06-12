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
    func otherWebKitErrorsArePresented() {
        let error = NSError(
            domain: WKError.errorDomain,
            code: WKError.Code.webContentProcessTerminated.rawValue
        )

        #expect(HotwireNavigationErrorPolicy.shouldPresent(error))
    }
}
