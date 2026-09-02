# XDIconButton Design

`XDCheckboxButton`, `XDMoreButton` and `XDCloseButton` are 44-point controls
for high-frequency list, card and overlay actions. Their visual icons are 24
points and centered in the control, so adjacent buttons do not overlap hit areas
while the visual matches the Figma specification. Hit-test expansion remains as
a fallback only when a caller explicitly constrains a button below the theme's
minimum hit size.

`XDCheckboxButton` additionally accepts `visualSize`: `.standard` (default)
keeps the 24-point icon, while `.small` switches to the dedicated 16-point
selected/unselected assets for dense layouts. The icon stays centered and the
control still reserves the theme's minimum hit target regardless of the visual
size. `XDCloseButton` accepts `visualSize: .large` for a 28-point icon with the
same hit-target rule.

The checkbox defaults to immediate state changes and emits `.valueChanged` plus
`onValueChanged`. In `.requiresConfirmation` mode it first emits
`onValueChangeRequest`, becomes pending, then commits through
`resolveSelectionChange(to:)` or returns to its prior state through
`cancelSelectionChange()`. Pending uses the disabled visual treatment and blocks
repeat taps. The more and close buttons are stateless and only invoke `onTap`.
All use package assets in their original rendering mode and resolve disabled
opacity through the bound theme context.
