# XDDesignKit API Stability

## Versioning

XDDesignKit follows semantic versioning after `1.0.0`. Before `1.0.0`, public API changes must still be recorded in `PROJECT_NOTES.md` and validated in the demo before integration.

## Public API rules

- Default to `internal`; expose only application-facing capabilities.
- UIKit views are `final` unless inheritance is an explicit extension point.
- Extensible identifiers use `RawRepresentable` structs with static members, not public enums that clients may exhaustively switch over.
- Adding a static token or style is source-compatible. Renaming or removing one is a breaking change.
- Public deprecations remain available for at least one minor release after `1.0.0` and include a migration message.
- Theme snapshots are immutable. Theme mutation is performed only through `XDThemeContext` on the main actor.
- Components must resolve visual values through an injected `XDThemeContext` and `XDThemeResolver`; global shortcuts are application-level conveniences only.

## Merge gate

Every public API change must include:

- XCTest coverage for behavior and failure paths.
- A demo state covering normal, boundary, dark mode, and alternate theme behavior.
- Strict-concurrency and warning-free builds through `Scripts/verify.sh`.
- Documentation updates when usage or architecture changes.
