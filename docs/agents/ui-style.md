# UI Style & Responsive Design

How agents should build UI in this project: reuse custom components, follow the desktop design language, and keep a **single responsive** layout (viewport width), not platform-specific page trees.

## Current state vs target

| Aspect | Today | Remaining target |
|--------|-------|------------------|
| Layout | **One** responsive shell (`ResponsiveAppShell`) via `AppLayoutBreakpoints` | Compact density / placement polish where still awkward |
| Theme | `buildAppTheme` everywhere (`app.dart`) | Keep desktop Fluent-inspired look on all widths |
| Routing | Single `appRouter` | — |
| Pages | Shared views under `views/` (no `desktop/` / `mobile/` trees) | Replace residual stock Material controls when touching a screen |

**Rule for new work:** Do not add new mobile-only Material pages or resurrect `views/mobile/`. Build with desktop custom components and responsive layout. When editing a screen, prefer converging leftover Material widgets toward the catalog below.

Shell / theme entry points:

- `app/lib/ui/features/shell/views/app.dart` — `buildAppTheme` (light/dark)
- `app/lib/ui/features/shell/views/routing/app_router.dart` — single `appRouter` + `ResponsiveAppShell`
- `app/lib/ui/core/layout/app_layout_breakpoints.dart` — compact / medium / expanded
- `app/lib/core/util/utils.dart` — `isDesktop` for **window chrome only** (Windows / macOS / Linux; not web); do not fork page trees on it

---

## Design language (desktop = source of truth)

Desktop UI is a **custom, Fluent-inspired** surface — not stock Material. Extracted from `app/lib/ui/core/theme/`.

### Overall feel

- Flat surfaces with **1px subtle borders** (`cs.hentai.borderSubtle`) rather than heavy Material elevation
- **Layered soft shadows** on cards and dialogs (ambient + lift + contact)
- **No splash / ripple** on desktop (`NoSplash.splashFactory`, transparent `highlightColor`)
- Short **easeOutCubic** transitions (~180–220 ms) for hover, sidebar, tabs
- Hover states on desktop (`MouseRegion`, `GhostButton` hover backgrounds)
- **Lucide** icons (`lucide_icons_flutter`) on desktop — avoid Material `Icons.*` in new desktop-style UI
- Locale: `zh_CN`; copy is Chinese in product UI

### Typography

- Default font: **`MI_Sans_Regular`** (set in `buildAppTheme`)
- Reader monospace: `RobotoMono` where needed
- Use `context.tokens.text` sizes — do not invent arbitrary font sizes:

| Token | Size (px) | Typical use |
|-------|-----------|-------------|
| `labelXs` | 12 | Chips, meta labels |
| `bodySm` | 13 | Secondary body |
| `bodyMd` | 14 | Default body, ghost button labels |
| `bodyLg` | 16 | Emphasized body |
| `titleSm` | 16 | Section titles |
| `titleMd` | 18 | Page subtitles |
| `titleLg` | 22 | Page titles |

Weight pattern: `w500`–`w600` for labels and titles; normal for body.

### Spacing & radius

Read from `context.tokens` — never hard-code one-off spacing in new components:

| Spacing | px | Radius | px |
|---------|-----|--------|-----|
| `xs` | 4 | `xs` | 4 |
| `sm` | 8 | `sm` | 6 |
| `md` | 12 | `md` | 8 |
| `lg` | 16 | `lg` | 12 |
| `xl` | 20 | `pill` | 999 |

Content area default: `tokens.layout.contentAreaPadding` (48 horizontal, 16 vertical).

### Color system

Two layers — use both, not raw hex in widgets:

1. **`Theme.of(context).colorScheme`** — Material 3 roles (`primary`, `surface`, `onSurfaceVariant`, …)
2. **`colorScheme.hentai`** (`HentaiColorScheme`) — app-specific semantic colors

Key semantic groups in `HentaiColorScheme`:

| Group | Examples | Use |
|-------|----------|-----|
| Text | `textPrimary`, `textSecondary`, `textTertiary`, `textPlaceholder` | Hierarchy |
| Borders | `borderSubtle`, `borderMedium`, `borderStrong` | Cards, inputs, dividers |
| Surfaces | `winBackground`, `winSurface`, `sidebarBackground` | App chrome |
| Sidebar | `sidebarItemHoverBackground`, `sidebarItemActiveBackground`, … | `DesktopSidebar` |
| Cards | `cardShadow`, `cardShadowHover`, `hoverBackground` | Hover lift |
| Inputs | `inputBackground`, `inputBorder`, `inputBorderActive` | `FluentTextField` |
| Reader | `readerBackground`, `readerPanelBackground`, `floatingUiBackground` | Reader overlay UI |
| Context menu | `contextMenuBackground`, `contextMenuHover`, `contextMenuDanger` | Right-click menus (danger labels / icons; menu alignment follow-up is out of current scope) |
| Status | `success`, `warning`, `error` | Toast, validation |
| Destructive | `destructive`, `onDestructive` | Delete / remove / clear **confirm** filled buttons (`DestructiveFilledButton`). Hue initially matches `contextMenuDanger`; do not use Material `error` for these confirms. |

**Primary accent:** light `#005FB8`, dark `#6EB3FF`. Secondary green for positive actions.

### Surfaces & chrome

- App background: `cs.hentai.winBackground`
- Primary content panels: `cs.surface` with `borderSubtle` border
- Sidebar: fixed widths `DesktopSidebar.expandedWidth` (256) / `collapsedWidth` (72)
- Dialogs: `HentaiDialog` — default 8px radius (overridable per dialog), multi-layer shadow, max width ~420 default
- **Adaptive form surfaces** (`AdaptiveFormSurface` / `showAdaptiveFormSurface`): medium/expanded → centered dialog; compact (`< 600`) → full-page under `AppTitleBar`, with live morph (~200ms `easeOutCubic`) across the breakpoint. Use for multi-field editors; keep confirm/progress dialogs on `HentaiDialog`. Compact metric-style details may turn off the footer divider and use a caption + large number body.
- **Metadata edit** (`EditMetadataDialog`): 720px max dialog width, 4px radius; side tabs on medium/expanded, `CapsuleTabBar` on compact; presented via `AdaptiveFormSurface`; General tab may include Series member sort order when the comic has a `SeriesItem`
- **Series edit** (`EditSeriesDialog`): same adaptive shell (480px max dialog width)
- Toasts: `showCustomToast` / `showSuccessToast` / `showErrorToast` — compact bottom-center; medium/expanded bottom-right (max 380 medium, 480 expanded); solid fill + layered shadow, no border — **not** `SnackBar` on desktop

### Interaction patterns

- **Primary actions:** filled buttons with `tokens.radius.md` shape
- **Destructive confirms:** delete / remove / clear confirmation dialogs use `DestructiveFilledButton` (`cs.hentai.destructive` / `onDestructive`). Cancel stays a plain `TextButton`. Do **not** paint non-delete confirms (e.g. save library root, disable all formats) with destructive. Menu / overflow / sidebar delete entry styling may still use `contextMenuDanger` until a follow-up issue.
- **Secondary / toolbar:** `GhostButton.icon`, `.iconText`, `.text` — hover fill, no splash
- **In-page tabs:** `CapsuleTabBar` (pill container, selected segment tinted with `primary`)
- **Context actions:** right-click → `*ContextMenu.show` (comic, series, series item)
- **Confirmations:** `HentaiDialog` or `*ConfirmDialog` under `overlays/dialog/confirm/`
- **Forms:** `FluentTextField`, `FluentDatePickerField`, `FluentToggleField`, `CustomTextField`, `*MultiSelectField`

### Card & list item pattern

Catalog grid cards share `CatalogCoverCardShell` (internal chrome + 2:3 edge-to-edge cover). Pages use `ComicCard` / `SeriesCard`, not the shell directly.

```
CatalogCoverCardShell
  border: borderSubtle 1px
  radius: tokens.radius.xs (4)
  background: cs.surface
  rest → cardShadow; hover → cardShadowHover
  clip: same xs radius (cover flush to top/sides; square bottom edge)
  └── cover (2:3, no hover scale/shadow) → ComicCoverContent / placeholder
  └── info padding: left/right/bottom sm; gap from cover: spacing.md
      title + meta (hover → primary title color)
```

`MetaChip` / `TagChip`: `surfaceContainerHighest` fill, 8px radius, icon 14px + label 12px w600.

---

## Component catalog

**Prefer these over raw Material widgets** when building or extending UI. All live under `app/lib/ui/core/widgets/`.

| Category | Path | Examples |
|----------|------|----------|
| Actions | `actions/` | `GhostButton`, `DestructiveFilledButton`, `FilterPopupButton`, `SortPopupButton`, `PopupMenuPanelShell` |
| Chrome | `chrome/` | `AppTitleBar`, `CapsuleTabBar`, `StatusCardShell` |
| Elements | `element/` | `CatalogCoverCardShell` (internal), `ComicCard`, `SeriesCard`, `MetaChip`, `TagChip`, `ContentRatingChip`, `AppComicImage`, `AdaptiveCover` |
| Feedback | `feedback/` | `custom_toast`, `TerminalSpinner` |
| Form | `form/` | `FluentTextField`, `CustomTextField`, `DatePicker`, `DatePickerField`, `FluentToggleField`, `MultiSelect`, `AuthorLibraryMultiSelectField`, `TagLibraryMultiSelectField` |
| Foundation | `foundation/` | `MyToggleSwitch` |
| Navigation | `navigation/` | `DesktopSidebar`, `LibraryReturnBreadcrumb` |
| Overlays | `overlays/dialog/` | `HentaiDialog`, `AdaptiveFormSurface`, `EditMetadataDialog`, `EditSeriesDialog`, `ScanProgressDialog`, … |
| Overlays | `overlays/context_menu/` | `ComicContextMenu`, `SeriesContextMenu`, … |
| Layout | `responsive_layout/` | `DetailResponsiveLayout`, `LibraryBlocksSliverGroup`, `LibrarySectionSliver` |

Theme entry points:

- `app/lib/ui/core/theme/theme.dart` — `buildAppTheme`, `HentaiColorScheme`, extensions
- `app/lib/ui/core/theme/theme_layout_tokens.dart` — `AppThemeTokens`, `context.tokens`

---

## Responsive layout

### Existing helpers

- **`AppLayoutBreakpoints`** — canonical widths: compact `< 600`, medium `600–1024`, expanded `≥ 1024` (`app/lib/ui/core/layout/app_layout_breakpoints.dart`).
- **`ResponsiveAppShell`** — compact drawer / medium collapsed sidebar / expanded sidebar; wraps all app routes.
- **`DetailResponsiveLayout`** — centers detail content at 80% of parent, clamped width 980–1320, height 560–920. Use for comic/series detail bodies.
- **`LibraryBlocksSliverGroup`** — standard library page sliver composition (series block + comics block).
- **`LayoutBuilder` + `MediaQuery`** — prefer for local density; do not add new `isDesktop` page forks.

### Breakpoints (codified)

| Width | Layout direction |
|-------|------------------|
| `< 600` | Compact: drawer nav, single column, full-width surfaces |
| `600 – 1024` | Medium: collapsed sidebar rail; denser grids |
| `≥ 1024` | Expanded: full `DesktopSidebar` + main content |

When narrowing: keep **desktop visual style** (colors, borders, GhostButton, custom cards) — only change **density and placement**, not Material defaults.

### Navigation

- Expanded / medium: `DesktopSidebar` + `AppTitleBar` (rail vs full labels via shell).
- Compact: same sidebar content in a **drawer** opened from the shell / page menu — do **not** add a separate Material `NavigationBar` stack or new Material-only nav chrome.
- Icons: `LucideIcons` in shell and new UI; avoid Material `Icons.*`.

---

## Anti-patterns

- Adding `Card` + `ListTile` + `OutlineInputBorder` pages in new code
- Using `Color(0xFF…)` in widgets when `cs.hentai.*` or `colorScheme.*` exists
- Creating `views/mobile/` (or any platform page tree) instead of making shared widgets responsive
- `SnackBar` on desktop — use `showCustomToast`
- Material `Icons` in desktop-target UI — use `LucideIcons`
- Stock `AlertDialog` for new flows — use `HentaiDialog` or confirm dialogs in `overlays/dialog/confirm/`
- Reintroducing `mobileRouter` / a second theme for “phone only”

---

## File layout convention

```
app/lib/ui/features/<feature>/views/   # shared screens (no desktop/ vs mobile/ split)
app/lib/ui/core/widgets/               # shared custom components — extend here first
app/lib/ui/core/layout/                # breakpoints / layout primitives
```

New shared screens: place widgets in `core/widgets` if cross-feature; keep feature-specific composition under `views/` without a `desktop/` / `mobile/` split.
