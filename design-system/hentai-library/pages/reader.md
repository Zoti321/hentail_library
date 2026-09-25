# Page Override: Reader

**Route:** `/reader?...` · **Widget:** `ReaderPage`  
**Overrides:** `MASTER.md`

---

## Purpose

Immersive comic reading: paged/scroll modes, chrome overlay, series nav, settings, auto-play. **Page image fidelity** per `CONTEXT.md` is mandatory.

## Layout

- **Always dark theme:** `buildAppTheme(Brightness.dark)` on reader shell
- Background: `cs.hentai.readerBackground` (`#09090B`)
- Full-screen scaffold; shell sidebar hidden
- Chrome: `ReaderTopBar`, `ReaderBottomBar`, `ReaderFloatingPanel` — toggle visibility; `keepControlsOpen` route arg
- Content: `ReaderContent` + `ReaderImageItem` — no unauthorized scaling/filtering

## Components

- `ReaderOverflowMenu` — settings entry
- `ReaderSettingsDialog` — reader prefs on dark surface
- `ReaderSeriesNav` — prev/next comic in series
- `ReaderOpenErrorPanel` / `ReaderOpenErrorMessage` — open failures
- Input: `reader_input.dart` — keyboard/tap zones
- Motion: `app_motion.dart` — respect reduced motion

## Interactions

- Route args: `comicId`, `incognito`, `startFromFirstPage`, `keepControlsOpen` via `ReaderRouteArgs`
- Shell rebuild isolation: page turns must not rebuild chrome (`readerControllerProvider` select pattern)
- Auto-play boundaries: `auto_play_boundary.dart`
- Toast: `showCustomToast` for non-blocking reader feedback
- Back: pop or exit reader route

## Anti-Patterns (This Page)

- ❌ Applying light theme to reader chrome
- ❌ Image filters, forced fit that crops page content against fidelity rules
- ❌ Rebuilding top/bottom bar on every page index change
- ❌ Material ripple on tap zones
- ❌ SnackBar over reader content

## Page Checklist

- [ ] Page images rendered at correct fidelity (no blur upscale cheat)
- [ ] Controls auto-hide unless `keepControlsOpen`
- [ ] Incognito session doesn't write history
- [ ] Keyboard shortcuts documented in `reader_input.dart` still work
- [ ] Error panel offers retry/back without white flash
- [ ] Floating UI uses `floatingUiBackground` token
