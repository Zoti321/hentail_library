# Page Override: Home

**Route:** `/home` · **Widget:** `HomePage`  
**Overrides:** `MASTER.md`

---

## Purpose

Dashboard entry: greeting, library stats, quick scan, deferred content sections (recent / recommendations). First screen after launch.

## Layout

| Tier | Width | Behavior |
|------|-------|----------|
| Compact | `<600` | Single column; menu ghost button in header |
| Medium | `600–1023` | Wider inner max-width; pinned header |
| Expanded | `≥1024` | Full sidebar + centered content column |

- Use `PageContentWidthAlign` + `homeContentHorizontalPadding` / `homeInnerContentMaxWidth` — do not invent widths.
- **Pinned header:** measure via `_headerMeasureKey` → `HomePinnedHeaderDelegate`; preserve this pattern when editing header.
- Background: `cs.hentai.winBackground`.

## Components

- `HomePageHeaderSection` — greeting, scan CTA, nav opener
- Scan action → `ScanProgressDialog` (barrier not dismissible while running)
- Section blocks deferred until `deferredSectionsReady` post-frame — avoid blocking first paint

## Interactions

- Primary CTA: scan library (`GhostButton` / filled per existing header — match siblings)
- Transitions: shell nav page (no fade-through)

## Anti-Patterns (This Page)

- ❌ Blocking entire page on section providers before showing header
- ❌ Material `FloatingActionButton` for scan
- ❌ Removing pinned header without replacing scroll-offset behavior

## Page Checklist

- [ ] Header pins correctly after measure
- [ ] Empty library state surfaces in deferred sections
- [ ] Scan opens progress dialog, not toast-only feedback
- [ ] Compact shows drawer opener; expanded does not duplicate nav
