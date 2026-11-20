# ADR-0066: Image set image dimensions in catalog

## Status

Accepted

## Context

Image set detail gallery needs stable cell height on first paint (color skeleton, then bytes). Dart header/codec peek after loading page bytes still delays layout. Lazy FRB probe still needs N reads before the grid can reserve height. Comic pages also lack catalog pixel size; Image set gallery is the first product surface that needs it.

## Decision

1. Persist optional **Image set image dimensions** (`width` / `height`) on `image_set_images` and expose them on `ImageSetImageDto` (list, workspace, reader pages, copy-in results).
2. Observe dimensions during Image set sync inserts and copy-in via `ImageReader::into_dimensions` (decode headers, not a full raster). Loose files stream from disk; archive members are read as entries because listing APIs here do not expose header-only peeks. Unchanged carriers that skip re-list keep prior rows (including nulls). Do not require open-detail backfill in this decision.
3. Reject Dart-only peek or ephemeral probe-only APIs as the catalog source of truth for gallery layout reservation.

## Consequences

- Sync/copy may open newly inserted members to probe dimensions (loose: streamed header decode; archives: entry bytes) — acceptable cost for first-paint stability.
- Existing rows stay null until a future re-insert or explicit backfill; UI falls back to a fixed aspect skeleton when dimensions are absent.
- FRB/Dart domain models carry optional width/height alongside path identity.

## References

- ADR-0062 (discovery boundary)
- ADR-0064 (workspace / sync append semantics)
- GLOSSARY: Image set image dimensions
