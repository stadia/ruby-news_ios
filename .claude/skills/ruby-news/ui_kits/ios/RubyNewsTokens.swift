// RubyNewsTokens.swift
// Design tokens for Ruby-News iOS app.
// Mirrors `colors_and_type.css` — values converted from OKLCH to sRGB hex.
// Reference the web kit when in doubt: keep these in lockstep.

import SwiftUI

// MARK: - Color tokens

extension Color {
    /// Hex initializer — `Color(hex: 0x16A571)` or `Color(hex: 0x16A571, alpha: 0.1)`
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8)  & 0xFF) / 255.0
        let b = Double( hex        & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

/// Semantic palette. Use these — never raw hex in views.
/// Resolves dark/light automatically from the system color scheme.
enum RNColor {
    // Surfaces
    static let bgApp          = Color("rn/bg-app",          dark: 0x0F0F0F, light: 0xFFFFFF)
    static let bgSurface      = Color("rn/bg-surface",      dark: 0x1A1A1A, light: 0xF7F7F7)
    static let bgSurfaceMuted = Color("rn/bg-surface-muted",dark: 0x262626, light: 0xE5E7EB)

    // Text
    static let textContent          = Color("rn/text",            dark: 0xFAFAFA, light: 0x141414)
    static let textContentSecondary = Color("rn/text-secondary",  dark: 0xE2E8F0, light: 0x1F2937)
    static let textContentMuted     = Color("rn/text-muted",      dark: 0xA3A3A3, light: 0x737373)

    // Borders
    static let borderStrong = Color("rn/border-strong", dark: 0xFFFFFF, light: 0xE5E7EB, darkAlpha: 0.10)
    static let borderSubtle = Color("rn/border-subtle", dark: 0xFFFFFF, light: 0xF1F5F9, darkAlpha: 0.04)

    // Brand — green ~150 hue, used functionally
    static let brand           = Color("rn/brand",           dark: 0x16A571, light: 0x0E8A5C)
    static let brandHover      = Color("rn/brand-hover",     dark: 0x0E8A5C, light: 0x086B47)
    static let brandForeground = Color("rn/brand-foreground",dark: 0xFFFFFF, light: 0xFFFFFF)
    static let accentText      = Color("rn/accent-text",     dark: 0x4ADE80, light: 0x0E8A5C)

    // Status
    static let infoText    = Color("rn/info-text",   dark: 0x60A5FA, light: 0x2563EB)
    static let infoSolid   = Color("rn/info-solid",  dark: 0x2563EB, light: 0x2563EB)
    static let dangerText  = Color("rn/danger-text", dark: 0xF87171, light: 0xDC2626)
    static let dangerSolid = Color("rn/danger-solid",dark: 0xDC2626, light: 0xDC2626)
}

private extension Color {
    /// Builds a dynamic color that switches on `userInterfaceStyle`.
    init(_ name: String, dark: UInt32, light: UInt32, darkAlpha: Double = 1.0, lightAlpha: Double = 1.0) {
        self = Color(UIColor { trait in
            let useDark = trait.userInterfaceStyle == .dark
            let hex = useDark ? dark : light
            let a = useDark ? darkAlpha : lightAlpha
            return UIColor(
                red:   CGFloat((hex >> 16) & 0xFF) / 255.0,
                green: CGFloat((hex >> 8)  & 0xFF) / 255.0,
                blue:  CGFloat( hex        & 0xFF) / 255.0,
                alpha: CGFloat(a)
            )
        })
    }
}

// MARK: - Type

/// Korean-first type stack — Noto Sans KR via CDN on web, system default ("Pretendard"/SF) on iOS.
/// Bundle a `NotoSansKR-Regular/Medium/Bold` font file and register it in Info.plist if you want
/// pixel-parity with the web — `Font.custom("NotoSansKR-Regular", size: ...)`.
enum RNFont {
    static func body(_ size: CGFloat = 14) -> Font { .system(size: size, weight: .regular) }
    static func bodyMedium(_ size: CGFloat = 14) -> Font { .system(size: size, weight: .medium) }
    static func bodyBold(_ size: CGFloat = 14) -> Font { .system(size: size, weight: .bold) }

    /// Display scale matches web: 12 / 14 / 16 / 18 / 20 / 24 / 30 / 36 / 48
    static let xs    = Font.system(size: 12, weight: .regular)
    static let sm    = Font.system(size: 14, weight: .regular)
    static let base  = Font.system(size: 16, weight: .regular)
    static let lg    = Font.system(size: 18, weight: .semibold)
    static let xl    = Font.system(size: 20, weight: .semibold)
    static let xl2   = Font.system(size: 24, weight: .bold)
    static let xl3   = Font.system(size: 30, weight: .bold)   // page title (mobile)
    static let xl4   = Font.system(size: 36, weight: .bold)   // page title (large)
}

// MARK: - Spacing & shape

enum RNSpacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xl2: CGFloat = 48
}

enum RNRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 8       // buttons, inputs
    static let lg: CGFloat = 12      // cards
    static let xl: CGFloat = 16      // article-detail surface
    static let xl2: CGFloat = 24     // profile card
}

// MARK: - Motion

enum RNMotion {
    /// 150 / 200 / 300 ms with cubic-bezier ease — never bouncy.
    static let fast = Animation.easeOut(duration: 0.15)
    static let base = Animation.easeOut(duration: 0.20)
    static let slow = Animation.easeInOut(duration: 0.30)
}
