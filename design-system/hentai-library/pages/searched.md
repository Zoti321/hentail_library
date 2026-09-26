# Page Override: Search Results

**Route:** `/searched?q=` · **Widget:** `SearchedPage`  
**Overrides:** `MASTER.md`

---

## Purpose

Full-page search results across the current library context. Shows query in header, comic grid, load-more.

## Layout

- Mirrors library/history shell: pinned `SearchedPageHeader` + scrollable grid
- Load-more threshold: **400px**
- Header measure pattern: `_headerMeasureKey` → `_headerExtent`

## Components

- `SearchedPageHeader` — query display, back/nav, optional library actions via `LibraryManagementActions`
- `ComicCard` grid — same card chrome as library catalog
- `EditMetadataDialog` — available from card actions (don't duplicate editor UI inline)
- Empty/zero-results state in header or grid placeholder

## Interactions

- Query from route `state.uri.queryParameters['q']` — URL is source of truth
- Card context menu / navigation to `/comic/:id`
- Preserve pinned header on scroll

## Anti-Patterns (This Page)

- ❌ Local-only query state that diverges from URL
- ❌ Different card component than catalog (visual inconsistency)
- ❌ Full-screen `CircularProgressIndicator` blocking header

## Page Checklist

- [ ] Empty query handled gracefully
- [ ] Results count / hint visible in header
- [ ] Load-more throttled like history page
- [ ] Deep link with `q` param restores same results
