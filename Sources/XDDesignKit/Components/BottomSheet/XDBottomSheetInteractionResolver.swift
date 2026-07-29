import UIKit

@MainActor
enum XDBottomSheetWidthResolver {
    static func resolve(
        _ strategy: XDBottomSheetWidth,
        windowWidth: CGFloat,
        safeAreaInsets: UIEdgeInsets
    ) -> CGFloat {
        let resolvedWindowWidth = max(1, windowWidth)
        let safeAreaWidth = max(
            1,
            resolvedWindowWidth - safeAreaInsets.left - safeAreaInsets.right
        )
        switch strategy.storage {
        case .fullWidth:
            return resolvedWindowWidth
        case .horizontalInsets(let inset):
            return max(1, safeAreaWidth - 2 * inset)
        case .centered(let maximum):
            return min(safeAreaWidth, maximum)
        }
    }
}

@MainActor
enum XDBottomSheetScrollResolution {
    case none
    case single(UIScrollView)
    case ambiguous
}

@MainActor
enum XDBottomSheetScrollResolver {
    static func resolve(in rootView: UIView) -> XDBottomSheetScrollResolution {
        var candidates: [UIScrollView] = []
        collectCandidates(in: rootView, into: &candidates)

        switch candidates.count {
        case 0:
            return .none
        case 1:
            return .single(candidates[0])
        default:
            return .ambiguous
        }
    }

    static func isAtTop(_ scrollView: UIScrollView) -> Bool {
        scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + 0.5
    }

    private static func collectCandidates(in view: UIView, into candidates: inout [UIScrollView]) {
        guard !view.isHidden, view.alpha > 0.01, view.isUserInteractionEnabled else { return }

        if let scrollView = view as? UIScrollView,
           scrollView.isScrollEnabled,
           scrollView.alwaysBounceVertical
                || scrollView.contentSize.height + scrollView.adjustedContentInset.top
                    + scrollView.adjustedContentInset.bottom > scrollView.bounds.height + 0.5 {
            candidates.append(scrollView)
        }

        for subview in view.subviews {
            collectCandidates(in: subview, into: &candidates)
        }
    }
}

enum XDBottomSheetKeyboardGeometry {
    static func dockedOverlap(in bounds: CGRect, keyboardFrame: CGRect) -> CGFloat {
        let intersection = bounds.intersection(keyboardFrame)
        guard !intersection.isNull, intersection.width > 0.5 else { return 0 }
        guard keyboardFrame.maxY >= bounds.maxY - 1 else { return 0 }
        return max(0, bounds.maxY - max(bounds.minY, keyboardFrame.minY))
    }
}
