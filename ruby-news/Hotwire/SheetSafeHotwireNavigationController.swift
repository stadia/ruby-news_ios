//
//  SheetSafeHotwireNavigationController.swift
//  ruby-news
//

import HotwireNative
import UIKit

/// Hotwire의 `NavigationHierarchyController`는 default-context 방문마다
/// `navigationController.dismiss(animated:)`를 호출해 내부 modal 스택을 정리한다.
/// 이 네비게이션 컨트롤러가 SwiftUI `.sheet` 안에 호스팅돼 있으면, 정리할
/// modal이 없는 경우 UIKit이 dismiss 호출을 상위 프레젠터(시트 호스트)에게
/// 전달해 시트 자체가 닫혀버린다. 자신이 띄운 modal이 없을 때의 dismiss는
/// 무시해 이 경로를 차단한다. 사용자가 시트를 내릴 때는 SwiftUI가 별도로
/// 처리하므로 영향이 없다.
final class SheetSafeHotwireNavigationController: HotwireNavigationController {
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        guard presentedViewController != nil else {
            completion?()
            return
        }
        super.dismiss(animated: flag, completion: completion)
    }
}
