import enum ObjectLibrary.Die
import class UIKit.UIImage

extension Die {
    /// Convenience variable for linking assets to `Die` enum cases
    var face: UIImage? { UIImage(named: rawValue) }
}
