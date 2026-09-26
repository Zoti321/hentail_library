# Page Override: Series Detail

**Route:** `/series/:id` · **Widget:** `SeriesDetailPage`  
**Overrides:** `MASTER.md`

---

## Purpose

Series metadata, ordered member comics, pagination, edit series. Fade-through route like comic detail.

## Layout

- Surface: `cs.surface`
- **Primary row:** `DetailPrimaryRowLayout` in `SeriesDetail`
- Member grid: `SeriesDetailComicCard` (series-specific card variant)
- Pagination: `SeriesDetailPaginationBar`
- Header: `SeriesDetailHeader` + info sections

## Components

- `EditSeriesDialog` — `AdaptiveFormSurface`, 480px max dialog width
- `SeriesDetailInfoSections` — description, counts, dates
- States: `SeriesDetailLoading`, `SeriesNotFound`, `SeriesDetailError`
- Context menu on member cards aligned with library

## Interactions

- Member card → `/comic/:id` or reader
- Series edit from header overflow / edit action
- Transition: `buildDesktopFadeThroughPage`

## Anti-Patterns (This Page)

- ❌ Reusing `ComicCard` directly for members (use `SeriesDetailComicCard`)
- ❌ Client-side sort that ignores series order from domain
- ❌ Full-page loader without header skeleton

## Page Checklist

- [ ] Member order matches series sort from backend
- [ ] Pagination state synced with grid
- [ ] Not-found series id handled
- [ ] Edit dialog uses adaptive shell on compact
