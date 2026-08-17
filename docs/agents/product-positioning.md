# Product Positioning

What this app is, what it is not, and which comic resource formats are in scope. Use this before scoping features, issues, or refactors.

## What we are building

**Hentai Library** is a **cross-platform comic reading and management app** for a personal library. Users maintain one or more **Libraries** (Komga-style: one **Library root** per Library). Roots are either **local folders** or **user-hosted WebDAV** endpoints. The app scans for comic resources, organizes them (Series, Tags, Authors), and reads in-app. There is **no** official cloud account, storefront, or social layer.

| Capability | In scope |
|------------|----------|
| Scan & sync comic files into a Library (local disk) | Yes |
| Remote Library via user-hosted WebDAV (streamed read) | Yes |
| Multiple Libraries with per-Library config (e.g. format groups) | Yes |
| Browse, search, filter within the Current library; Reading history global | Yes |
| Read comics in-app (paged / scroll layouts) | Yes |
| Manage metadata, series order, reading history | Yes |
| Cross-platform desktop + mobile | Yes (UI converging to responsive desktop style) |
| Official cloud sync, accounts, storefront | No |
| WebDAV backup of settings/DB (separate future issue) | Not in current WebDAV library-source work |
| General-purpose ebook library (novels, textbooks) | No — comic-first |

Domain vocabulary (Library, Library root, Comic, Library sync, …) lives in **`CONTEXT.md`**. This file covers product scope and format support only.

## Platforms

| Platform | Status |
|----------|--------|
| Windows / macOS / Linux | Primary today (`isDesktop`) |
| Android / iOS | Supported; legacy Material UI, migrating to responsive desktop-style UI |
| Web | Not a current target (`isDesktop` treats web as non-desktop) |

**Local libraries** remain offline-first after scan. **Remote (WebDAV) libraries** require network for reading and sync; generated thumbnails may be cached locally as derived data. Prefer HTTPS; users may explicitly allow HTTP for LAN NAS.

## Comic resource types

A **Resource** is a file or directory (local) or WebDAV file (remote) that can become a **Comic** after validation. Target support spans **image archives**, **image folders** (local), **EPUB**, and **PDF**.

### Target format matrix

| Format | Extensions | Category | Local | Remote (WebDAV) first slice |
|--------|------------|----------|-------|------------------------------|
| Image directory | _(folder)_ | Loose images | Supported | Out of scope (first slice) |
| ZIP archive | `.zip` | Comic archive | Supported | Supported |
| CBZ | `.cbz` | Comic archive | Supported | Supported |
| RAR archive | `.rar` | Comic archive | Supported | Supported |
| CBR | `.cbr` | Comic archive | Supported | Supported |
| 7z archive | `.7z` | Comic archive | Supported | Supported |
| CB7 | `.cb7` | Comic archive | Supported | Supported |
| EPUB | `.epub` | Structured ebook | Supported | Supported |
| PDF | `.pdf` | Document | Supported* | Supported* |

\* PDF: desktop + Android via pdfium; iOS still stub (local and remote).

“Comic archive” means a compressed file whose readable pages are **images**. Archives are not opaque blobs — the app extracts or streams page images for the reader.

### Implementation status (codebase today)

| `ResourceType` | Scan | Read | Notes |
|----------------|------|------|-------|
| `dir` | Yes | Yes | Local only for now |
| `zip` / `cbz` | Yes | Yes | |
| `epub` | Yes | Yes | |
| `cbr` / `rar` | Yes | Yes | `unrar-ng` |
| `cb7` / `sevenz` | Yes | Yes | |
| `pdf` | Yes* | Yes* | iOS stub |

**Planned:** Multi-Library + WebDAV Remote library (see ADR-0008); PDF on iOS. Core scan/read/DB live in Rust (`core/`) via FRB; see `docs/agents/rust-migration.md` and ADR-0002.

### Out of scope (unless explicitly requested)

- Proprietary store formats (e.g. Kindle AZW)
- Video, audio, or non-page media as primary comic content
- Online manga scraping or download
- Official hosted cloud library or accounts
- Mirroring entire remote comics to disk as the primary remote model

## Agent guidance

- Describe the product as a **personal comic library** with optional **user-hosted WebDAV** roots — not a generic file manager, ebook app, or SaaS cloud reader.
- Use **Library** / **Library root** / **Current library** / **Local library** / **Remote library** from `CONTEXT.md`; treat **Saved path** as the legacy name for a local root.
- Prefer **Comic** / **Resource** / **Library sync** / **Resource access** in issues and PRs.
- New reader or scan features should extend Resource access → Comic → Reader rather than Flutter-only protocol forks (e.g. do not put WebDAV page I/O primarily in `cached_network_image`).
