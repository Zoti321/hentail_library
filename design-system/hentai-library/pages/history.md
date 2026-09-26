# Page Override: History

**Route:** `/history` · **Widget:** `HistoryPage`  
**Overrides:** `MASTER.md`

---

## Purpose

Global reading history feed (cross-library). Search/filter within history, paged grid, resume reading.

## Layout

- `PageContentWidthAlign` + `contentSearchWidth` constraints
- **Pinned header:** `HistoryPageHeader` via `_headerMeasureKey`
- Grid: `ReadingHistoryCard`, main axis spacing **12px** (`_kHistoryGridMainAxisSpacing`)
- Load-more threshold: **400px** from bottom — keep throttle via `history_load_more_throttle`

## Components

- `CustomTextField` — history search in header
- `ReadingHistoryCard` — 2:3 cover + progress meta
- Cover viewport: `history_cover_viewport_notifier` (mirror library pattern)
- Open reader: `ReaderRouteArgs` + `appRootNavigatorKey` as existing

## Interactions

- Tap card → navigate to reader with saved progress
- Toast feedback via `showCustomToast` family on errors
- Compact: header includes nav opener like other shell pages

## Anti-Patterns (This Page)

- ❌ Scoping history to current library only (product: global history)
- ❌ `SnackBar` for load errors
- ❌ Material grid cards instead of `ReadingHistoryCard`

## Page Checklist

- [ ] Search debounce/throttle matches header implementation
- [ ] Load-more doesn't duplicate-fetch on fast scroll
- [ ] Cover lazy-load respects viewport notifier
- [ ] Resume opens correct comic + incognito flags unchanged
