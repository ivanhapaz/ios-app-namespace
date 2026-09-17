import UIKit

/// Code-generated repeating floor patterns (no image files). Each returns a
/// small tile to be assigned to a floor material with `wrapS = wrapT = .repeat`.
enum FloorTextures {

    /// Cobbles for the Courtyard: a 2-colour checker.
    static func cobble() -> UIImage {
        checker(UIColor(hex: 0xA79C85), UIColor(hex: 0x948B78))
    }

    /// Flagstones for the Chapel: a paler 2-colour checker.
    static func flagstone() -> UIImage {
        checker(UIColor(hex: 0xCFC6AE), UIColor(hex: 0xC2B8A0))
    }

    /// Stone flags for the Kitchens.
    static func kitchenStone() -> UIImage {
        checker(UIColor(hex: 0xA79C85), UIColor(hex: 0x948B78))
    }

    /// Planks for the Great Hall / Privy Chamber: single-axis stripes.
    static func plank() -> UIImage {
        stripe(UIColor(hex: 0x8A6238), UIColor(hex: 0x7C5730))
    }

    // MARK: Generators

    private static func checker(_ a: UIColor, _ b: UIColor) -> UIImage {
        let cell: CGFloat = 32
        let size = CGSize(width: cell * 2, height: cell * 2)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let c = ctx.cgContext
            c.setFillColor(a.cgColor)
            c.fill(CGRect(origin: .zero, size: size))
            c.setFillColor(b.cgColor)
            c.fill(CGRect(x: cell, y: 0, width: cell, height: cell))
            c.fill(CGRect(x: 0, y: cell, width: cell, height: cell))
        }
    }

    private static func stripe(_ a: UIColor, _ b: UIColor) -> UIImage {
        let pitch: CGFloat = 32
        let size = CGSize(width: pitch * 2, height: pitch * 2)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let c = ctx.cgContext
            c.setFillColor(a.cgColor)
            c.fill(CGRect(origin: .zero, size: size))
            c.setFillColor(b.cgColor)
            c.fill(CGRect(x: 0, y: 0, width: size.width, height: pitch))
            // a thin darker seam between planks
            c.setFillColor(UIColor(hex: 0x5E4526).cgColor)
            c.fill(CGRect(x: 0, y: pitch - 1.5, width: size.width, height: 1.5))
            c.fill(CGRect(x: 0, y: size.height - 1.5, width: size.width, height: 1.5))
        }
    }
}
