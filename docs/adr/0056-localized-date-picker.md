# ADR-0056: Localized application-owned date picker

## Status

Accepted, 2026-11-14. Supersedes only ADR-0053's fixed-English calendar subtree and material_ui localization requirement for the new date picker.

## Context

The metadata editor's calendar forced English, committed a date during year navigation, and used a fixed-size overlay that could extend outside the viewport.

## Decision

The design system owns the new month/year calendar and responsive presentation, using Flutter MaterialLocalizations and the host's localization delegates. Legacy M3E calendar primitives retain their existing material_ui bridge. The new component does not consume application ARB types.

Month and year selection navigate without committing. Both docked and modal pickers hold a draft until explicit confirmation; cancellation preserves the field. Docked pickers have independent month/year controls, replacing lists, outside-month context and a dynamic week-row count. They retain a 360 logical-pixel width on wide layouts and use the actual content height for placement.

Below 600 logical pixels the picker uses a modal with a selected-date header, divider, calendar/input toggle, horizontal month swipes and a vertically scrolling year grid. Compact viewports below 392 pixels wide or 600 pixels tall use a full-screen modal with close/save affordances. Small viewports constrain the surface and allow vertical scrolling rather than proportionally enlarging the calendar.

Keyboard navigation includes arrows, Home/End, Page Up/Down, Shift+Page Up/Down and month/year menu shortcuts. Flutter table semantics expose complete dates and weekday headers. Motion follows design-system timing and bypasses size animations for reduced motion.

## Consequences

Supported languages follow the host MaterialApp supportedLocales and GlobalMaterialLocalizations delegates; there is no calendar-specific translation table. ISO yyyy-MM-dd remains the metadata field's storage and editing format. The existing M3EDatePickerMode parameter remains for caller compatibility, without using M3E date-picker rendering.

## References

- https://m3.material.io/components/date-pickers/
- https://m3.material.io/components/date-pickers/specs
- https://m3.material.io/components/date-pickers/guidelines
- https://m3.material.io/components/date-pickers/accessibility
