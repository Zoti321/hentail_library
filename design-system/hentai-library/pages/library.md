# Page Override: Library Catalog

**Route:** `/libraries/:libraryId` · **Widget:** `LibraryBrowsePage` → `LibraryPage`  
**Overrides:** `MASTER.md`

---

## Purpose

Primary catalog for the **Current library**: series block + comics grid, search toolbar, filter/sort drawer, pagination.

## Layout

- `CustomScrollView` + slivers via `LibraryBlocksSliverGroup`
- **Pinned header:** search toolbar measured with `_headerMeasureKey`
- **Compact:** end drawer for `library_filter_sort_drawer` — track `_isEndDrawerOpen`
- Cover viewport throttling: 75ms min interval — preserve when touching scroll listeners

| Width | Grid / blocks |
|-------|----------------|
| Compact | Single column blocks; drawer filters |
| Medium | Denser grid via `LibraryBlocksLayout` |
| Expanded | Full grid + sidebar visible |

## Components

- `LibrarySearchToolbar` — pinned header
- `LibrarySeriesBlock` / `LibraryComicsBlock` — catalog sections
- `ComicCard` / `SeriesCard` via `CatalogCoverCardShell`
- `LibraryPaginationBarSliver` — bottom pagination
- Empty states: `library_comic_empty_slivers`
- Context menus: comic/series right-click handlers

## Interactions

- Filter/sort: end drawer (compact) — do not add bottom sheet Material pattern on desktop widths
- Card hover: shadow lift only (`cardShadowHover`), no scale
- Right-click → existing `*ContextMenu.show`

## Anti-Patterns (This Page)

- ❌ Forking separate mobile `LibraryPage`
- ❌ Disabling cover viewport throttle without replacement (perf regression)
- ❌ Stock `Drawer` + `ListTile` filter UI

## Page Checklist

- [ ] Library switch via route param syncs `currentLibraryProvider`
- [ ] Pinned toolbar height stable after locale/font change
- [ ] Pagination + infinite patterns don't fight scroll-to-top
- [ ] Empty library vs empty filter states distinct
