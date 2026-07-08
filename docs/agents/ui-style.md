# UI Style & Responsive Design

How agents should build UI in this project: reuse custom components, follow the desktop design language, and move toward a single responsive layout instead of platform-specific pages.

## Current state vs target

| Aspect | Today | Target |
|--------|-------|--------|
| Layout | Desktop and mobile use **separate** page trees and routers | **One responsive** UI that adapts to viewport width |
| Theme | Desktop: custom Fluent-inspired theme (`buildAppTheme`) | **Desktop theme everywhere** |
| Theme | Mobile: stock Material 3 from seed (`buildMobileMaterialTheme`) | Retire mobile Material look |
| Routing | `isDesktop ? desktopRouter : mobileRouter` | Single router; layout adapts inside shared pages |
| Pages | `lib/ui/features/**/views/desktop/` vs `views/mobile/` | Shared views under `views/` (or desktop widgets reused responsively) |

**Rule for new work:** Do not add new mobile-only Material pages. Build with desktop custom components and responsive layout. When touching mobile pages, prefer converging them toward the desktop look.

Platform switch today lives in:

- `lib/ui/features/shell/views/app.dart` — theme selection
- `lib/ui/features/shell/views/routing/app_router.dart` — router selection
- `lib/core/util/utils.dart` — `isDesktop` (Windows / macOS / Linux; not web)

---

## Design language (desktop = source of truth)

Desktop UI is a **custom, Fluent-inspired** surface — not stock Material. Extracted from `lib/ui/core/theme/`.

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
| Context menu | `contextMenuBackground`, `contextMenuHover`, `contextMenuDanger` | Right-click menus |
| Status | `success`, `warning` | Toast, validation |

**Primary accent:** light `#005FB8`, dark `#6EB3FF`. Secondary green for positive actions.

### Surfaces & chrome

- App background: `cs.hentai.winBackground`
- Primary content panels: `cs.surface` with `borderSubtle` border
- Sidebar: fixed widths `DesktopSidebar.expandedWidth` (256) / `collapsedWidth` (72)
- Dialogs: `HentaiDialog` — 8px radius, multi-layer shadow, max width ~420 default
- Toasts: `showCustomToast` / `showSuccessToast` / `showErrorToast` — bottom-right, max 380px — **not** `SnackBar` on desktop

### Interaction patterns

- **Primary actions:** filled buttons with `tokens.radius.md` shape
- **Secondary / toolbar:** `GhostButton.icon`, `.iconText`, `.text` — hover fill, no splash
- **In-page tabs:** `CapsuleTabBar` (pill container, selected segment tinted with `primary`)
- **Context actions:** right-click → `*ContextMenu.show` (comic, series, series item)
- **Confirmations:** `HentaiDialog` or `*ConfirmDialog` under `overlays/dialog/confirm/`
- **Forms:** `FluentTextField`, `CustomTextField`, `DatePickerField`, `*MultiSelectField`

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

**Prefer these over raw Material widgets** when building or extending UI. All live under `lib/ui/core/widgets/`.

| Category | Path | Examples |
|----------|------|----------|
| Actions | `actions/` | `GhostButton`, `FilterPopupButton`, `SortPopupButton`, `PopupMenuPanelShell` |
| Chrome | `chrome/` | `AppTitleBar`, `CapsuleTabBar`, `StatusCardShell` |
| Elements | `element/` | `CatalogCoverCardShell` (internal), `ComicCard`, `SeriesCard`, `MetaChip`, `TagChip`, `ContentRatingChip`, `AppComicImage`, `AdaptiveCover` |
| Feedback | `feedback/` | `custom_toast`, `TerminalSpinner` |
| Form | `form/` | `FluentTextField`, `CustomTextField`, `DatePicker`, `DatePickerField`, `MultiSelect`, `AuthorLibraryMultiSelectField`, `TagLibraryMultiSelectField` |
| Foundation | `foundation/` | `MyToggleSwitch` |
| Navigation | `navigation/` | `DesktopSidebar`, `LibraryReturnBreadcrumb` |
| Overlays | `overlays/dialog/` | `HentaiDialog`, `AddSeriesDialog`, `EditMetadataDialog`, `ScanProgressDialog`, … |
| Overlays | `overlays/context_menu/` | `ComicContextMenu`, `SeriesContextMenu`, … |
| Layout | `responsive_layout/` | `DetailResponsiveLayout`, `LibraryBlocksSliverGroup`, `LibrarySectionSliver` |

Theme entry points:

- `lib/ui/core/theme/theme.dart` — `buildAppTheme`, `HentaiColorScheme`, extensions
- `lib/ui/core/theme/theme_layout_tokens.dart` — `AppThemeTokens`, `context.tokens`
- `lib/ui/core/theme/mobile_material_theme.dart` — **legacy mobile only; do not extend**

---

## Responsive layout

### Existing helpers

- **`DetailResponsiveLayout`** — centers detail content at 80% of parent, clamped width 980–1320, height 560–920. Use for comic/series detail bodies.
- **`LibraryBlocksSliverGroup`** — standard library page sliver composition (series block + comics block).
- **`LayoutBuilder` + `MediaQuery`** — preferred for new breakpoints; do not add new `isDesktop` page forks.

### Suggested breakpoints (not yet codified in code — follow when implementing responsive work)

| Width | Layout direction |
|-------|------------------|
| `< 600` | Single column; bottom or compact nav; full-width cards |
| `600 – 1024` | Reduced sidebar or drawer; 2-column grids |
| `≥ 1024` | Sidebar + main content (current desktop shell) |

When narrowing: keep **desktop visual style** (colors, borders, GhostButton, custom cards) — only change **density and placement**, not Material defaults.

### Navigation migration notes

- Desktop: `DesktopSidebar` + `AppTitleBar`
- Mobile (legacy): `NavigationBar` + `AppBar` + Material `Icons` — replace with responsive shell using sidebar drawer or bottom bar styled with `HentaiColorScheme`

---

## Anti-patterns

- Adding `Card` + `ListTile` + `OutlineInputBorder` pages (current mobile library pattern) in new code
- Using `Color(0xFF…)` in widgets when `cs.hentai.*` or `colorScheme.*` exists
- Creating `views/mobile/` duplicates instead of making desktop widgets responsive
- `SnackBar` on desktop — use `showCustomToast`
- Material `Icons` in desktop-target UI — use `LucideIcons`
- Stock `AlertDialog` for new flows — use `HentaiDialog` or confirm dialogs in `overlays/dialog/confirm/`

---

## File layout convention (during migration)

```
lib/ui/features/<feature>/views/
  desktop/          # current primary implementation — design reference
  mobile/           # legacy Material implementations — converge away
lib/ui/core/widgets/  # shared custom components — extend here first
```

New shared screens: place widgets in `core/widgets` if cross-feature; keep feature-specific composition in `views/` without a `desktop/` / `mobile/` split when possible.
