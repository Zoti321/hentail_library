# Page Override: Settings

**Route:** `/settings` · **Widget:** `SettingsPage` → `SettingsView`  
**Overrides:** `MASTER.md`

---

## Purpose

App preferences: theme, locale, metadata backup, diagnostics, about. **List–detail** master pattern — hides app sidebar while open.

## Layout

| Width | Pattern |
|-------|---------|
| Compact `<600` | Category list **or** detail pane (`showingNarrowDetail`); back affordance between |
| Medium+ | Split: category list + detail pane side-by-side |

- Constants: `settings_layout_constants.dart` — use `settingsLayoutTierForWidth`, `settingsContentHorizontalPadding`
- Pinned header: `SettingsPageHeader` with measure key
- Shell: settings route hides sidebar (see `CONTEXT.md` Settings list–detail)

## Components

- `SettingsPageHeader` — title + compact back when in detail
- Rows: `ThemePreferenceRow`, `LocalePreferenceRow`, `SettingsMetadataBackupRows`, `SettingsDiagnosticsRows`, `SettingsAboutRows`
- Primitives: `settings_page_primitives.dart` — row dividers, section headers
- Icons: Lucide throughout

## Interactions

- Category selection: in-page state (`SettingsCategory` enum) — **no child routes** for categories
- Wide → narrow transition resets detail visibility via `wasWide` ref
- Loading/error: center indicator / error text on `SettingsPage` shell only

## Anti-Patterns (This Page)

- ❌ Adding GoRoute per settings section (use list–detail)
- ❌ Showing app sidebar alongside settings split pane
- ❌ Material `SwitchListTile` without Fluent-style row wrapper

## Page Checklist

- [ ] Compact back navigation from detail to category list
- [ ] Theme/locale changes apply via existing providers
- [ ] Diagnostics rows don't expose secrets in UI copy
- [ ] Header pins after measure on rotation
