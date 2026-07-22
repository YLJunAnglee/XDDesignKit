# XDAlert Design

`XDAlert` is a scene-bound centered UIKit dialog. Its public API exposes only
standard content configuration; the internal presentation shell owns the mask,
card, transition, theme binding, accessibility focus, and dismissal lifecycle.

## Standard content

- Optional title and body text. Both default to adaptive alignment: short text is
  centered, while text that exceeds the available single-line width uses natural
  leading alignment.
- Callers may independently set title and body alignment to adaptive, leading,
  or centered through `XDAlertConfiguration`.
- Optional illustration and supporting caption.
- Optional bounded accessory: checkbox or text field.
- Optional actions. Filled, outlined, and text actions reuse `XDButton` styles.

## Theme contract

All visual values resolve from the injected `XDThemeContext`. Alert-specific
colors, typography, and metrics live in `XDAlertTheme`, under
`XDThemeComponents.alert`. A call site may pass a scene-local context to
`XDAlert.show(on:configuration:themeContext:)`.

The default layout follows the Figma Alerts specification: a 300-point maximum
card width, 12-point radius, theme-owned card and section insets, 16-point
section spacing, and 10-point action spacing. These values remain component
metrics rather than view-level literals.

## Checkbox contract

Selected and unselected checkbox images ship in the Swift Package resource
bundle. The visual row follows the 24-point design size, while hit testing uses
the theme's independent 44-point minimum target. The full row, including its
trailing empty area, toggles the control.

## Extension boundary

`XDAlertViewController` depends on the internal `XDAlertContentRendering`
protocol rather than standard-content views. A future custom-content renderer
can replace only the card body while retaining the scene, transition,
accessibility, and theme shell.

## 0.5.0 hardening status

The standard-content boundary remains internal. Version 0.5.0 adds the public
`XDAlertTextAlignment` policy and independent title/message configuration while
preserving source compatibility through adaptive defaults. The hardening pass
provides:

1. A height-constrained scroll container and keyboard avoidance for long
   content, accessibility text sizes, landscape, and text input.
2. Theme-owned overlay color, interaction sizes, and presentation scale;
   action spacing and illustration constraints refresh with the active theme.
3. Explicit attributed-text alignment, a 44-point close hit area, and an
   accessible checkbox with package-owned images, row-level interaction, label,
   value, selected, and disabled states.
4. A scene-owned coordinator that serializes presentation, cancels queued
   requests, recovers from rejected UIKit presentations, and advances the queue
   after dismissal. Callers still provide an explicit, scene-attached UIKit
   host; failures are reported through `XDAlertHandle.presentationFailure`.
5. Configurable width-based alignment and committed-text length enforcement that
   does not interrupt marked text from Chinese and other input methods.

The Figma checkbox variant, bundled resources, hit target, adaptive/forced text
alignment, package tests, and Demo build have been verified. Manual verification
remains required for the wider matrix of keyboard, VoiceOver, repeated
presentation, and all device sizes. Snapshot regression coverage remains a
later project-wide addition.
