import SwiftUI
import UIKit

/// Design tokens for the "Illuminated manuscript — Cinzel" direction (2b).
/// Colours, fonts, and the signature nested-rule panel frame live here so every
/// screen stays consistent with the handoff spec.
enum Theme {
    // MARK: UI palette (SwiftUI overlay)
    static let parchment = Color(hex: 0xE8DCC0)
    static let parchmentLight = Color(hex: 0xF1E8D2)
    static let goldLeaf = Color(hex: 0xC9A227)
    static let vermilion = Color(hex: 0xA6301F)
    static let lapis = Color(hex: 0x2B4C7E)
    static let ink = Color(hex: 0x23201B)
    static let danger = Color(hex: 0x7A2016)
    static let ruleBrown = Color(hex: 0x9E8A63)
    static let track = Color(hex: 0xD2C3A2)
    static let mutedText = Color(hex: 0x5E5442)
    static let pressedFill = Color(hex: 0xF7F0DE)

    // MARK: Typography
    // Display uses Copperplate (iOS inscriptional caps) as the sanctioned
    // fallback for Cinzel; body uses Iowan Old Style (ships with iOS).
    static func display(_ size: CGFloat) -> Font {
        Font.custom("Copperplate-Bold", size: size)
    }
    static func displayLight(_ size: CGFloat) -> Font {
        Font.custom("Copperplate", size: size)
    }
    static func body(_ size: CGFloat) -> Font {
        Font.custom("Iowan Old Style", size: size)
    }
    static func bodyItalic(_ size: CGFloat) -> Font {
        Font.custom("Iowan Old Style", size: size).italic()
    }
}

extension UIColor {
    convenience init(hex: UInt) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

/// Roman numerals for day counts (`DAY XIV`) and choice markers.
func romanNumeral(_ value: Int) -> String {
    guard value > 0 else { return "0" }
    let table: [(Int, String)] = [
        (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"),
        (100, "C"), (90, "XC"), (50, "L"), (40, "XL"),
        (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")
    ]
    var remaining = value
    var result = ""
    for (amount, symbol) in table {
        while remaining >= amount {
            result += symbol
            remaining -= amount
        }
    }
    return result
}

// MARK: - Manuscript panel frame

/// One inner rule: the parchment gutter *before* it, its colour, and width.
struct FrameRule {
    let gutter: CGFloat
    let color: Color
    var width: CGFloat = 1
}

extension View {
    /// The signature framing: a 1pt `ruleBrown` outer outline, then a stack of
    /// inset gold/vermilion/danger rules with parchment gutters showing through.
    func manuscriptPanel(radius: CGFloat = 0,
                         fill: Color = Theme.parchment,
                         inner: [FrameRule] = [FrameRule(gutter: 3, color: Theme.goldLeaf)],
                         shadowRadius: CGFloat = 20,
                         shadowY: CGFloat = 16) -> some View {
        background(fill)
            .overlay(RuleStack(radius: radius, inner: inner))
            .shadow(color: .black.opacity(0.45), radius: shadowRadius, y: shadowY)
    }
}

/// A parchment button whose fill lightens on press (no scale, no shadow change),
/// wrapped in the manuscript rule frame.
struct ManuscriptButtonStyle: ButtonStyle {
    var fill: Color
    var pressedFill: Color
    var inner: [FrameRule]
    var vPad: CGFloat
    var hPad: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, vPad)
            .padding(.horizontal, hPad)
            .frame(maxWidth: .infinity)
            .manuscriptPanel(fill: configuration.isPressed ? pressedFill : fill,
                             inner: inner, shadowRadius: 0, shadowY: 0)
    }
}

/// Gold line — coloured device — gold line, used under titles and setups.
struct DividerRule: View {
    enum Device { case dot, diamond }
    var device: Device = .dot
    var lineColor: Color = Theme.goldLeaf
    var deviceColor: Color = Theme.vermilion

    var body: some View {
        HStack(spacing: 8) {
            Rectangle().fill(lineColor).frame(height: 1)
            marker
            Rectangle().fill(lineColor).frame(height: 1)
        }
    }

    @ViewBuilder private var marker: some View {
        switch device {
        case .dot:
            Circle().fill(deviceColor).frame(width: 6, height: 6)
        case .diamond:
            Rectangle().fill(deviceColor).frame(width: 10, height: 10).rotationEffect(.degrees(45))
        }
    }
}

/// Draws the concentric rules as strokeBorders inset by cumulative padding.
private struct RuleStack: View {
    let radius: CGFloat
    let inner: [FrameRule]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .strokeBorder(Theme.ruleBrown, lineWidth: 1)
            ForEach(Array(insets.enumerated()), id: \.offset) { _, spec in
                RoundedRectangle(cornerRadius: max(0, radius - spec.inset))
                    .strokeBorder(spec.color, lineWidth: spec.width)
                    .padding(spec.inset)
            }
        }
    }

    /// Cumulative inset for each inner rule (outer rule is 1pt).
    private var insets: [(inset: CGFloat, color: Color, width: CGFloat)] {
        var running: CGFloat = 1
        var out: [(CGFloat, Color, CGFloat)] = []
        for rule in inner {
            running += rule.gutter
            out.append((running, rule.color, rule.width))
            running += rule.width
        }
        return out
    }
}
