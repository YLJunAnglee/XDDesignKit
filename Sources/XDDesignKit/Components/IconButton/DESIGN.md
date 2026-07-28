# XDIconButton Design

`XDCheckboxButton`, `XDMoreButton` and `XDCloseButton` are 44-point controls
for high-frequency list, card and overlay actions. Their visual icons are 24
points and centered in the control, so adjacent buttons do not overlap hit areas
while the visual matches the Figma specification. Hit-test expansion remains as
a fallback only when a caller explicitly constrains a button below the theme's
minimum hit size.

The checkbox toggles itself and emits `.valueChanged` plus `onValueChanged`.
The more and close buttons are stateless and only invoke `onTap`. All use
package assets in their original rendering mode and resolve disabled opacity
through the bound theme context.
