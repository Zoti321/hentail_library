# Design System Master File

> **LOGIC:** When building a specific page, first check `design-system/hentai-library/pages/[page-name].md`.
> If that file exists, its rules **override** this Master file.
> If not, strictly follow the rules below.

---

**Project:** Hentai Library  
**Stack:** Flutter (responsive desktop-style shell)  
**Initialized:** 2026-09-25 via ui-ux-pro-max  
**Authoritative source:** `docs/agents/ui-style.md` — this file summarizes agent-facing rules; when in doubt, read the doc and theme code.

### Page Overrides Index

| Page file | Route | Widget |
|-----------|-------|--------|
| [home.md](pages/home.md) | `/home` | `HomePage` |
| [all-libraries.md](pages/all-libraries.md) | `/libraries/all` | `AllLibrariesBrowsePage` |
| [library.md](pages/library.md) | `/libraries/:libraryId` | `LibraryPage` |
| [history.md](pages/history.md) | `/history` | `HistoryPage` |
| [searched.md](pages/searched.md) | `/searched?q=` | `SearchedPage` |
| [settings.md](pages/settings.md) | `/settings` | `SettingsPage` |
| [metadata.md](pages/metadata.md) | `/metadata?tab=` | `MetadataManagementPage` |
| [comic-detail.md](pages/comic-detail.md) | `/comic/:id` | `ComicDetailPage` |
| [series-detail.md](pages/series-detail.md) | `/series/:id` | `SeriesDetailPage` |
| [reader.md](pages/reader.md) | `/reader?...` | `ReaderPage` |
| [route-not-found.md](pages/route-not-found.md) | `/series` (invalid) | `RouteNotFoundPage` |

Legacy redirect-only routes (`/local`, `/paths`, `/tags`, …) inherit the target page override — no separate file.

---

## Product Context

Cross-platform **comic library** app: scan/sync local or WebDAV roots, browse catalog (Series, Tags, Authors), read in-app. Content-first, Chinese-first copy (`zh` / `en` l10n). **Single responsive shell** — no separate mobile/desktop page trees.

| Aspect | Rule |
|--------|------|
| Layout | `ResponsiveAppShell` + `AppLayoutBreakpoints` |
| Theme | `buildAppTheme` in `app/lib/ui/features/shell/views/app.dart` |
| Breakpoints | compact `<600` · medium `600–1023` · expanded `≥1024` |
| Window chrome | `isDesktop` (Windows/macOS/Linux only) — **not** for forking page trees |
| Icons | **Lucide** (`lucide_icons_flutter`) — avoid Material `Icons.*` in new UI |

---

## Global Rules

### Style Direction

**Fluent-inspired desktop surface** — flat panels, 1px subtle borders, layered soft shadows, no Material splash/ripple on desktop.

| Property | Value |
|----------|-------|
| Style | Minimal, content-first, geometric grid |
| Motion | `easeOutCubic`, **180–220 ms** (sidebar, tabs, hover) |
| Elevation | Prefer borders + layered shadow over heavy Material elevation |
| Density | Catalog grids medium-dense; reader chrome minimal |

### Color Palette

Use **`Theme.of(context).colorScheme`** (M3 roles) **and** **`colorScheme.hentai`** (`HentaiColorScheme`). Never hard-code hex in widgets.

| Role | Light | Dark | Flutter access |
|------|-------|------|----------------|
| Primary accent | `#005FB8` | `#6EB3FF` | `colorScheme.primary` |
| App background | — | — | `cs.hentai.winBackground` |
| Content surface | — | — | `cs.surface` + `cs.hentai.borderSubtle` 1px |
| Sidebar | — | — | `cs.hentai.sidebarBackground` |
| Text primary | — | — | `cs.hentai.textPrimary` |
| Text secondary | — | — | `cs.hentai.textSecondary` |
| Border subtle | — | — | `cs.hentai.borderSubtle` |
| Destructive confirm | — | — | `cs.hentai.destructive` / `onDestructive` |
| Status | — | — | `success`, `warning`, `error` |
| Reader chrome | — | — | `readerBackground`, `floatingUiBackground` |

**Theme entry:** `app/lib/ui/core/theme/theme_visual_tokens.dart` → `HentaiColorScheme`

### Typography

| Token | Size | Use |
|-------|------|-----|
| `labelXs` | 12px | Chips, meta labels |
| `bodySm` | 13px | Secondary body |
| `bodyMd` | 14px | Default body, ghost button labels |
| `bodyLg` | 16px | Emphasized body |
| `titleSm` | 16px | Section titles |
| `titleMd` | 18px | Page subtitles |
| `titleLg` | 22px | Page titles |

- **UI font:** `MI_Sans_Regular` (via `buildAppTheme`)
- **Monospace:** `RobotoMono` (reader / code contexts)
- **Access:** `context.tokens.text.*` — do not invent arbitrary sizes
- **Weight:** `w500`–`w600` labels/titles; normal for body

### Spacing & Radius

Read from `context.tokens` — never one-off magic numbers in new components.

| Spacing | px | Radius | px |
|---------|-----|--------|-----|
| `xs` | 4 | `xs` | 4 |
| `sm` | 8 | `sm` | 6 |
| `md` | 12 | `md` | 8 |
| `lg` | 16 | `lg` | 12 |
| `xl` | 20 | `pill` | 999 |

Content area: `tokens.layout.contentAreaPadding` (48h / 16v).

### Shadows

Use semantic tokens — `cs.hentai.cardShadow`, `cardShadowHover` on catalog cards; multi-layer shadow on `HentaiDialog`. Do not copy generic CSS shadow tables from web stacks.

---

## Component Specs

Reuse widgets under `app/lib/ui/core/widgets/` before creating primitives.

| Category | Path |
|----------|------|
| Actions | `actions/` — filled primary, `GhostButton`, `DestructiveFilledButton` |
| Chrome | `chrome/` — `AppTitleBar`, sidebar |
| Form | `form/` — `FluentTextField`, `FluentDatePickerField`, `FluentToggleField` |
| Navigation | `navigation/` — `CapsuleTabBar` |
| Overlays | `overlays/dialog/`, `overlays/context_menu/` |
| Feedback | `feedback/` — `showCustomToast` (not desktop `SnackBar`) |

### Buttons

- **Primary:** filled, `tokens.radius.md` shape
- **Secondary / toolbar:** `GhostButton` — hover fill, no splash
- **Destructive confirm only:** `DestructiveFilledButton` — delete/remove/clear dialogs; cancel stays `TextButton`

### Cards (Catalog)

`CatalogCoverCardShell` → `ComicCard` / `SeriesCard`:

- Border: `borderSubtle` 1px · radius: `tokens.radius.xs` (4)
- Background: `cs.surface` · rest: `cardShadow` · hover: `cardShadowHover`
- Cover: 2:3 aspect, flush top/sides, no hover scale
- Info padding: sm L/R/bottom, `spacing.md` gap from cover

`MetaChip` / `TagChip`: `surfaceContainerHighest`, 8px radius, icon 14px + label 12px w600.

### Forms & Dialogs

- **Adaptive forms:** `AdaptiveFormSurface` / `showAdaptiveFormSurface` — dialog on medium+, full-page on compact
- **Confirm/progress:** `HentaiDialog` or `*ConfirmDialog`
- **Metadata edit:** `EditMetadataDialog` (720px max, side tabs medium+)
- **Toasts:** bottom-center compact · bottom-right medium/expanded (max 380/480)

### Reader

- Background: `cs.hentai.readerBackground`
- Floating UI: `floatingUiBackground`
- **Page image fidelity:** follow `CONTEXT.md` — no unauthorized scaling/filtering

---

## Layout Patterns

| Pattern | Guidance |
|---------|----------|
| Responsive | `LayoutBuilder` / breakpoint helpers — no fixed viewport widths |
| Catalog | Grid of `ComicCard` / `SeriesCard`; filters in sidebar or toolbar |
| Reader | Immersive; minimal chrome; respect safe areas on mobile |
| Sidebar | Expanded 256px / collapsed 72px (`DesktopSidebar`) |
| Compact nav | Drawer, not a separate Material mobile tree |

---

## Flutter Stack Notes

- **LayoutBuilder** for adaptive layouts — avoid fixed `Container(width: …)` for responsive regions
- **Semantics** on interactive controls without visible labels
- **No splash on desktop:** `NoSplash.splashFactory`, transparent `highlightColor`
- **Hover:** `MouseRegion` + ghost button hover backgrounds on desktop
- Test TalkBack / VoiceOver when adding non-obvious gestures

---

## Anti-Patterns (Do NOT Use)

- ❌ Separate `views/mobile/` or mobile-only Material page trees
- ❌ Material `Icons.*` or emojis as structural icons — use Lucide
- ❌ Raw hex colors in widgets — use `colorScheme` + `hentai` tokens
- ❌ Material ripple/splash on desktop chrome
- ❌ Desktop `SnackBar` — use `showCustomToast` family
- ❌ `error` color for non-destructive confirms
- ❌ Layout-shifting hover transforms on cards (shadow change only)
- ❌ Hard-coded spacing/font sizes outside `context.tokens`
- ❌ Forking UI on `isDesktop` for page structure (window chrome only)

---

## Pre-Delivery Checklist

- [ ] Reused existing widget from `ui/core/widgets/` where applicable
- [ ] Tokens from `context.tokens` and `cs.hentai` — no ad-hoc hex/spacing
- [ ] Lucide icons; consistent 14/24px sizing per context
- [ ] Hover/transition ~180–220 ms `easeOutCubic`; respect reduced motion
- [ ] Text contrast ≥4.5:1 in **both** light and dark themes
- [ ] Focus visible for keyboard navigation
- [ ] Responsive at 375px, 600px, 1024px, 1440px widths
- [ ] Compact: no content hidden behind fixed bars; adaptive form → full page when `<600`
- [ ] Semantics labels on icon-only controls
- [ ] Destructive styling only on delete/remove/clear confirms
