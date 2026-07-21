import UIKit

struct XDButtonLayoutInput {
    let bounds: CGRect
    let contentInsets: UIEdgeInsets
    let titleSize: CGSize
    let iconSize: CGSize
    let spacing: CGFloat
    let placement: XDButtonIconPlacement
    let isRightToLeft: Bool
    let horizontalAlignment: UIControl.ContentHorizontalAlignment
    let verticalAlignment: UIControl.ContentVerticalAlignment
}

struct XDButtonLayoutResult {
    let titleFrame: CGRect
    let iconFrame: CGRect
    let contentSize: CGSize
}

enum XDButtonLayout {
    static func calculate(_ input: XDButtonLayoutInput) -> XDButtonLayoutResult {
        let showsTitle = input.titleSize.width > 0 && input.titleSize.height > 0 && input.placement != .only
        let showsIcon = input.iconSize.width > 0 && input.iconSize.height > 0
        let spacing = showsTitle && showsIcon ? input.spacing : 0
        let available = CGRect(
            x: input.bounds.minX + input.contentInsets.left,
            y: input.bounds.minY + input.contentInsets.top,
            width: max(0, input.bounds.width - input.contentInsets.left - input.contentInsets.right),
            height: max(0, input.bounds.height - input.contentInsets.top - input.contentInsets.bottom)
        )

        var titleSize = showsTitle ? input.titleSize : .zero
        let iconSize = showsIcon ? input.iconSize : .zero
        let usesVerticalLayout = input.placement == .top || input.placement == .bottom

        if input.horizontalAlignment == .fill, showsTitle {
            titleSize.width = usesVerticalLayout
                ? available.width
                : max(0, available.width - iconSize.width - spacing)
        }
        if input.verticalAlignment == .fill, showsTitle {
            titleSize.height = usesVerticalLayout
                ? max(0, available.height - iconSize.height - spacing)
                : available.height
        }

        let contentSize: CGSize
        if usesVerticalLayout {
            contentSize = CGSize(
                width: max(titleSize.width, iconSize.width),
                height: titleSize.height
                    + iconSize.height
                    + spacing
            )
        } else {
            contentSize = CGSize(
                width: titleSize.width
                    + iconSize.width
                    + spacing,
                height: max(titleSize.height, iconSize.height)
            )
        }

        let origin = CGPoint(
            x: horizontalOrigin(contentWidth: contentSize.width, in: available, input: input),
            y: verticalOrigin(contentHeight: contentSize.height, in: available, alignment: input.verticalAlignment)
        )

        var titleFrame = CGRect(origin: origin, size: titleSize)
        var iconFrame = CGRect(origin: origin, size: iconSize)

        switch input.placement {
        case .top:
            iconFrame.origin.x += (contentSize.width - iconFrame.width) / 2
            titleFrame.origin.x += (contentSize.width - titleFrame.width) / 2
            titleFrame.origin.y += iconFrame.height + spacing
        case .bottom:
            titleFrame.origin.x += (contentSize.width - titleFrame.width) / 2
            iconFrame.origin.x += (contentSize.width - iconFrame.width) / 2
            iconFrame.origin.y += titleFrame.height + spacing
        case .trailing:
            layoutHorizontal(
                titleFrame: &titleFrame,
                iconFrame: &iconFrame,
                contentSize: contentSize,
                spacing: spacing,
                iconComesFirst: input.isRightToLeft
            )
        case .only:
            titleFrame = .zero
            iconFrame.origin.x += (contentSize.width - iconFrame.width) / 2
            iconFrame.origin.y += (contentSize.height - iconFrame.height) / 2
        default:
            layoutHorizontal(
                titleFrame: &titleFrame,
                iconFrame: &iconFrame,
                contentSize: contentSize,
                spacing: spacing,
                iconComesFirst: !input.isRightToLeft
            )
        }

        if input.placement == .leading || input.placement == .trailing {
            titleFrame.origin.y += (contentSize.height - titleFrame.height) / 2
            iconFrame.origin.y += (contentSize.height - iconFrame.height) / 2
        }

        return XDButtonLayoutResult(
            titleFrame: titleFrame,
            iconFrame: iconFrame,
            contentSize: contentSize
        )
    }

    private static func layoutHorizontal(
        titleFrame: inout CGRect,
        iconFrame: inout CGRect,
        contentSize: CGSize,
        spacing: CGFloat,
        iconComesFirst: Bool
    ) {
        if iconComesFirst {
            titleFrame.origin.x += iconFrame.width + spacing
        } else {
            iconFrame.origin.x += titleFrame.width + spacing
        }
    }

    private static func horizontalOrigin(
        contentWidth: CGFloat,
        in available: CGRect,
        input: XDButtonLayoutInput
    ) -> CGFloat {
        switch input.horizontalAlignment {
        case .left:
            return available.minX
        case .right:
            return available.maxX - contentWidth
        case .leading:
            return input.isRightToLeft ? available.maxX - contentWidth : available.minX
        case .trailing:
            return input.isRightToLeft ? available.minX : available.maxX - contentWidth
        case .fill:
            return contentWidth >= available.width ? available.minX : available.midX - contentWidth / 2
        default:
            return available.midX - contentWidth / 2
        }
    }

    private static func verticalOrigin(
        contentHeight: CGFloat,
        in available: CGRect,
        alignment: UIControl.ContentVerticalAlignment
    ) -> CGFloat {
        switch alignment {
        case .top:
            return available.minY
        case .bottom:
            return available.maxY - contentHeight
        case .fill:
            return contentHeight >= available.height ? available.minY : available.midY - contentHeight / 2
        default:
            return available.midY - contentHeight / 2
        }
    }
}
