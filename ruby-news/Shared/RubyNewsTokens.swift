// RubyNewsTokens.swift
// 디자인 토큰. 키트의 colors_and_type.css / ui_kits/ios/RubyNewsTokens.swift 와 동기.
// 현재는 브랜드 강조색만 노출 — 토큰만 사용하고, 뷰 내부에 raw hex 를 두지 않습니다.

import SwiftUI
import UIKit

extension Color {
    /// 브랜드 그린. 시스템 컴포넌트의 `.tint` 강조색으로 사용합니다.
    /// 다크 0x16A571 / 라이트 0x0E8A5C — 시스템 색상 스킴에 따라 자동 전환.
    static let rnBrand = Color(UIColor { trait in
        let hex: UInt32 = trait.userInterfaceStyle == .dark ? 0x16A571 : 0x0E8A5C
        return UIColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: 1.0
        )
    })
}
