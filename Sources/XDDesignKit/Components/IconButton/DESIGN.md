# XDIconButton Design

`XDCheckboxButton` and `XDMoreButton` are intentionally narrow 24-point icon
controls for high-frequency list and card actions. They preserve a 44-point
minimum hit area through hit-test expansion, while allowing surrounding layouts
to align the visual icon to the Figma specification.

When a parent view clips or does not forward out-of-bounds hits, the caller
should reserve a 44-point layout slot to guarantee the full hit target.

The checkbox toggles itself and emits `.valueChanged` plus `onValueChanged`.
The more button is stateless and only invokes `onTap`. Both use package assets
in their original rendering mode and resolve disabled opacity through the bound
theme context.
