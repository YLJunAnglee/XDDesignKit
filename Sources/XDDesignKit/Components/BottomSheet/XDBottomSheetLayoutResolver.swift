import UIKit

struct XDBottomSheetVerticalGeometry: Equatable {
    let contentBottomInset: CGFloat
    let maximumHeight: CGFloat

    func resolvedContentBottomInset(for surfaceHeight: CGFloat) -> CGFloat {
        min(contentBottomInset, max(0, surfaceHeight))
    }
}

enum XDBottomSheetVerticalGeometryResolver {
    static func resolve(
        containerHeight: CGFloat,
        safeAreaInsets: UIEdgeInsets,
        keyboardOverlap: CGFloat
    ) -> XDBottomSheetVerticalGeometry {
        let resolvedKeyboardOverlap = max(0, keyboardOverlap)
        let contentBottomInset = resolvedKeyboardOverlap > 0
            ? 0
            : max(0, safeAreaInsets.bottom)
        let maximumHeight = max(
            1,
            containerHeight - max(0, safeAreaInsets.top) - resolvedKeyboardOverlap
        )
        return XDBottomSheetVerticalGeometry(
            contentBottomInset: contentBottomInset,
            maximumHeight: maximumHeight
        )
    }
}
