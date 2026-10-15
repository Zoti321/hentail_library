# Page Override: Metadata Management

**Route:** `/metadata?tab=` · **Widget:** `MetadataManagementPage`  
**Overrides:** `MASTER.md`

---

## Purpose

Manage named facets: Tags, Authors, Parodies, Characters, Languages. Tabbed panels with search, CRUD, dictionary import.

## Layout

- `PageContentWidthAlign` + `metadata_layout_constants.dart`
- **Pinned header:** `MetadataPageHeader` + `CapsuleTabBar` (compact) or side tabs (medium+)
- Tab index from URL query `tab` — deep links `/tags`, `/authors`, etc. redirect here
- Scroll-to-top FAB: `LibraryScrollToTopButton` pattern when scrolled
- Keyboard: `_MetadataAddIntent` shortcut for add action

## Components

- `NamedFacetManagementPanel` — list + actions per facet
- `NamedFacetFillViewport` — empty/loading fill
- `MetadataContentSearch` — filter within tab
- Dialogs: `TagConfirmDeleteDialog`, `TagDictionaryImportDialog`
- Delete confirm: `DestructiveFilledButton` in confirm dialogs only

## Interactions

- Tab switch updates URL query (preserve back stack)
- Load-more on scroll via `_scrollController`
- Toast on success/error — not SnackBar
- `_visitedTabIndexes` — lazy-init heavy tabs

## Anti-Patterns (This Page)

- ❌ Separate routes per facet tab (use query param)
- ❌ Inline delete without confirm dialog
- ❌ EhTag import UI mixed with curated dictionary import flows

## Page Checklist

- [ ] Deep link `?tab=tags` opens correct panel
- [ ] Add shortcut works when panel focused
- [ ] Search filters current tab only
- [ ] Compact uses `CapsuleTabBar`; medium+ side tabs
