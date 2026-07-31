# Product Positioning

What this app is, what it is not, and which comic resource formats are in scope. Use this before scoping features, issues, or refactors.

## What we are building

**Hentai Library** is a **cross-platform comic reading and management app** for a personal local library.

Users point the app at folders on disk (**Saved paths**), scan for comic resources, organize them (Series, Tags, Authors), and read offline. There is no cloud library or social layer — everything runs against files on the user's machine.

| Capability | In scope |
|------------|----------|
| Scan & sync local comic files into a Library | Yes |
| Browse, search, filter (tags, authors, series, content rating) | Yes |
| Read comics in-app (paged / scroll layouts) | Yes |
| Manage metadata, series order, reading history | Yes |
| Cross-platform desktop + mobile | Yes (UI converging to responsive desktop style) |
| Cloud sync, accounts, storefront | No |
| General-purpose ebook library (novels, textbooks) | No — comic-first |

Domain vocabulary (Comic, Series, Library sync, …) lives in **`CONTEXT.md`**. This file covers product scope and format support only.

## Platforms

| Platform | Status |
|----------|--------|
| Windows / macOS / Linux | Primary today (`isDesktop`) |
| Android / iOS | Supported; legacy Material UI, migrating to responsive desktop-style UI |
| Web | Not a current target (`isDesktop` treats web as non-desktop) |

Offline-first: reading and library data work without network access after scan.

## Comic resource types

A **Resource** is a file or directory on disk that can become a **Comic** after validation. Target support spans **image archives**, **image folders**, **EPUB**, and **PDF**.

### Target format matrix

| Format | Extensions | Category | Target |
|--------|------------|----------|--------|
| Image directory | _(folder)_ | Loose images | Supported |
| ZIP archive | `.zip` | Comic archive (images inside) | Supported |
| CBZ | `.cbz` | Comic archive (ZIP convention) | Supported |
| RAR archive | `.rar` | Comic archive | Supported |
| CBR | `.cbr` | Comic archive (RAR convention) | Supported |
| 7z archive | `.7z` | Comic archive | Supported |
| CB7 | `.cb7` | Comic archive (7z convention) | Supported |
| EPUB | `.epub` | Structured ebook (comic EPUBs) | Supported |
| PDF | `.pdf` | Document | Supported (desktop; mobile stub) |

“Comic archive” means a compressed file whose readable pages are **images** (typical scanlation / doujin layout). Archives are not treated as opaque blobs — the app extracts or streams page images for the reader.

EPUB and PDF are supported as first-class comic carriers when content is comic-like (sequential pages / spreads), not as a replacement for dedicated novel readers.

### Implementation status (codebase today)

| `ResourceType` | Scan | Read | Notes |
|----------------|------|------|-------|
| `dir` | Yes | Yes | Folder of images |
| `zip` | Yes | Yes | |
| `cbz` | Yes | Yes | Same pipeline as zip |
| `epub` | Yes | Yes | Comic-oriented EPUB handling |
| `cbr` | Yes | Yes | Same pipeline as rar (`unrar-ng` / rarlab); desktop + mobile |
| `rar` | Yes | Yes | Desktop + mobile via `unrar-ng` |
| `cb7` | Yes | Yes | Same pipeline as sevenz |
| `sevenz` | Yes | Yes | Via `sevenz-rust` |
| `pdf` | Yes* | Yes* | Desktop via pdfium; Android/iOS still stub |

**Planned:** Remaining gap is **PDF on mobile** (pdfium vendor / linking). Core scan/read/DB already lives in Rust (`core/`) via FRB; see `docs/agents/rust-migration.md` and ADR-0002.

When adding format support during migration, extend `ResourceType`, implement parser and `PageSource` in Rust, expose via FRB; update Library sync progress counts for new types.

### Out of scope (unless explicitly requested)

- Proprietary store formats (e.g. Kindle AZW)
- Video, audio, or non-page media as primary comic content
- Online manga scraping or download

## Agent guidance

- Describe the product as a **local comic library**, not a generic file manager or ebook app.
- Treat **rar/cbr, 7z/cb7** as supported. **PDF on mobile** is still a stub — do not assume it works on Android/iOS.
- Prefer **Comic** / **Resource** / **Library sync** terms from `CONTEXT.md` in issues and PRs.
- New reader or scan features should fit the existing Resource → Comic → Reader pipeline rather than one-off per-format UI forks.
