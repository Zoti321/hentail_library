# Design-system development

ADR-0053 defines the complete visual/interaction system and its independent boundary. The only external entry is `app/lib/design-system/design_system.dart`; the root `design-system/` placeholder is not an implementation specification.

## Ownership and public API

The design system owns theme/tokens, layout/motion, keyboard/focus/accessibility, component state and complex input behavior. Components consume presentation data, image Widgets, loading/error flags and callbacks. They do not query repositories, read business providers, execute application navigation or consume application domain/ARB types. M3E widgets may be used directly without one wrapper per widget.

Product navigation, current-Library/flyout state, selection/reorder exclusion, domain pagination/metadata locks, file images/cache and application error mapping stay in `shared/ui` or their feature owner. Reader-specific chrome belongs to Reader. Judge ownership by responsibility, not by a Comic name or consumer count.

Consumers import `package:hentai_library/design-system/design_system.dart`. Each barrel export explicitly selects symbols with `show`; internal files use relative imports and do not import the barrel or re-export component chains. Keep application dependencies entirely inside the layer, including no dependency on core. The boundary scanner follows imports/exports/parts/conditional branches and third-party runtime declarations/source; missing files/packages fail rather than receiving a baseline exemption.

## Localization and host effects

Application ARB files in `app/l10n/` generate into `app/lib/l10n/` via `app/l10n.yaml`. Components use DesignSystemLocalizations for common English/Chinese text; hosts supply business messages. The application-owned date picker uses Flutter MaterialLocalizations and host delegates (ADR-0056). Legacy calendar primitives retain material_ui MaterialLocalizations through materialLocalizationsOf / MaterialUiLocalizationsScope.

Capture OverlayRouteScopeSnapshot synchronously at the call site to preserve theme, locale and delegates in root overlays. Window chrome consumes DesktopWindowActions callbacks; `infrastructure/window` performs native operations and `composition/window_composition` binds them for production/Widgetbook. A preview without a native host may disable window buttons.

## Preview and verification

Run `cd app && flutter run -t widgetbook/main.dart`. Widgetbook is the Lab visual acceptance surface. For FacetMultiSelectField, exercise Loaded/Loading/Error/Empty, candidate updates while the overlay is open, retry, pinyin, smart hints, clear, keyboard/IME and focus. Verify the date picker in Chinese and English, compact modal and wide docked layouts, large text and reduced motion. Add languages through the host supportedLocales and GlobalMaterialLocalizations delegates; no calendar translation table is needed. The metadata field retains ISO yyyy-MM-dd text, normalizes accepted separators only on submit/blur, and displays a format hint. CalendarDatePickerSurface owns the selection draft; both docked and modal variants commit only on confirmation. Widgetbook DatePicker provides Docked, Modal and Modal input cases with en/zh/fr/ar locale controls. Keep docked width at 360 logical pixels on larger viewports; adapt placement and available height rather than scaling it with the breakpoint. Browser preview can encounter the application's existing dart:io image-adapter limitation; widget tests are not visual sign-off.

Use `test/support/pump_design_system_app.dart` for independent components, without application ARB, ProviderScope or domain models. Product adapters use `pumpLocalizedApp` / existing `pumpApp`. Run affected behavior tests plus `test/design-system/design_system_boundary_test.dart` and `design_system_dependency_policy_test.dart`; check host/composition behavior when bindings change. Regenerate l10n/build_runner only when their inputs change. Follow [gate.md](gate.md) for lint, formatting and manifest promotion. Keep run-specific counts, screenshots and migration results in the PR.
