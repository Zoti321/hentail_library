# Page Override: Comic Detail

**Route:** `/comic/:id` · **Widget:** `ComicDetailPage`  
**Overrides:** `MASTER.md`

---

## Purpose

Single comic metadata, cover, series navigation, read CTA, edit metadata. Fade-through transition (outside shell nav stack).

## Layout

- Surface: `cs.surface` full bleed
- **Primary row:** `DetailPrimaryRowLayout` — cover + info column on compact, row on wider
- Scrollable detail sections below header
- `PopScope`: back → `ComicDetailBackHeader.popOrGoLibrary` when stack empty

## Components

- `ComicDetailHeader` / `ComicDetailBackHeader` — back + actions
- `ComicDetailInfoSections` — tags, dates, file info
- `ComicDetailSeriesNav` — prev/next in series
- `EditMetadataDialog` via `AdaptiveFormSurface`
- States: `ComicDetailLoading`, `ComicDetailNotFound`, `ComicDetailError`

## Interactions

- Read → `/reader?...` with `ReaderRouteArgs`
- Context actions consistent with catalog cards
- Transition: `buildDesktopFadeThroughPage` — don't wrap in shell nav page

## Anti-Patterns (This Page)

- ❌ Material `AppBar` with default back
- ❌ Edit form as stock `AlertDialog` (use adaptive form surface)
- ❌ Cover aspect ratio other than catalog 2:3 convention

## Page Checklist

- [ ] Invalid id shows not-found, not uncaught error
- [ ] Back navigates to library when no pop target
- [ ] `skipLoadingOnReload` preserved on provider watch
- [ ] Read button respects incognito / start page query flags
