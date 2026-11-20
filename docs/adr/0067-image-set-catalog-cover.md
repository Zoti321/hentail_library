# ADR-0067: Image set catalog cover persistence

## Status

Accepted

## Context

Comic and Series catalog covers persist pre-scaled JPEG (long edge ≤512) in SQLite (`comic_thumbnails` / `series_thumbnails`). Image set catalog cards and detail headers previously loaded the first workspace image via raw page bytes (`load_image_set_page_bytes`), decoding full-resolution sources for every cover paint. That path does not share Comic’s Catalog Cover contract and becomes expensive as Image set libraries grow. Gallery tiles and Read sessions correctly stay on page-bytes (ADR-0060/0065).

## Decision

- Persist one **catalog cover** JPEG per Image set in `image_set_thumbnails` (BLOB, long edge ≤512, quality aligned with Comic thumbs).
- Cover source is the default workspace first image (non-excluded, lowest `sort_order`), matching prior UI `list.first` behavior.
- Invalidate when workspace reorder/exclude changes the first image, or when carrier fingerprint (`source_modified_ms` / `source_size`) or `source_image_set_image_id` changes; cascade-delete with the Image set row.
- `ensure` / `find` live in the Image set owner (`image_set/cover.rs`); post-sync enqueues missing/stale covers at low priority. Do not put Image set ids into the Comic `ThumbnailQueue`.
- Flutter catalog cards/headers consume cover bytes (session LRU); detail gallery tiles and Reader continue to use page-bytes.
- Fingerprint / needs-generation reads use column projection only and never `SELECT` the thumbnail BLOB.

## Consequences

### Positive

- Image set catalog covers match Comic Catalog Cover cost and decode policy (`kCatalogImageFilterQuality`).
- Sync can report thumbnail progress for Image set libraries.

### Negative

- Additional SQLite BLOB storage per Image set; workspace first-image changes require regenerate.
- Gallery / Read are still not thumbnail-cached (out of scope for this decision).
