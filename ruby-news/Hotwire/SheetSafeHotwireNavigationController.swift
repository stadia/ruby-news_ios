//
//  SheetSafeHotwireNavigationController.swift
//  ruby-news
//

import HotwireNative
import UIKit

/// Hotwire의 `NavigationHierarchyController`는 default-context 방문마다
/// 내부 modal 스택 정리를 위해 `navigationController.dismiss(animated:)`를
/// 호출한다. 이 네비게이션 컨트롤러가 SwiftUI `.sheet` 안에 호스팅돼 있고
/// 정리할 modal이 없으면 UIKit이 dismiss를 상위 프레젠터(시트 호스트)에게
/// 전달해 시트 자체가 닫혀버린다.
///
/// 다음 두 조건을 모두 만족할 때의 dismiss만 차단한다:
///   1. 자신이 modal로 띄워진 상태 (`presentingViewController != nil`)
///   2. 자신이 띄운 내부 modal이 없음 (`presentedViewController == nil`)
///
/// 두 조건이 동시에 성립할 때만 dismiss가 외부 프레젠터로 escalation돼
/// 의도치 않은 컨테이너 dismissal을 일으킨다. 푸시/탭 루트 등 modal이
/// 아닌 컨텍스트나 내부 modal이 떠 있는 경우는 그대로 통과시켜 Hotwire의
/// 정상적인 back/done 흐름을 깨지 않는다.
final class SheetSafeHotwireNavigationController: HotwireNavigationController {
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if presentingViewController != nil && presentedViewController == nil {
            completion?()
            return
        }
        super.dismiss(animated: flag, completion: completion)
    }
}
