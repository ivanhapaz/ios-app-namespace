import SwiftUI

/// The always-visible four-meter banner. Suspicion is shown in red because,
/// unlike the others, a full bar is bad.
struct MetersHUD: View {
    let meters: Meters

    var body: some View {
        HStack(spacing: 12) {
            meter(icon: "crown.fill", value: meters.royalFavor, tint: Color(red: 0.85, green: 0.68, blue: 0.20))
            meter(icon: "flame.fill", value: meters.piety, tint: Color(red: 0.90, green: 0.55, blue: 0.20))
            meter(icon: "bag.fill", value: meters.wealth, tint: Color(red: 0.35, green: 0.62, blue: 0.35))
            meter(icon: "eye.fill", value: meters.suspicion, tint: Color(red: 0.80, green: 0.25, blue: 0.25))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.black.opacity(0.38), in: Capsule())
    }

    private func meter(icon: String, value: Int, tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.18)).frame(width: 42, height: 6)
                Capsule().fill(tint).frame(width: 42 * CGFloat(value) / 100.0, height: 6)
            }
        }
    }
}
