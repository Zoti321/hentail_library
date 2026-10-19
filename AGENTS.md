## Agent skills

### Architecture

Rust core / FRB / monorepo (`app/` Flutter, `core/` Rust): **`docs/agents/rust-core.md`**; read `docs/adr/` entries that touch the area (background: ADR-0002).

### Product

Personal comic library (local roots and user-hosted WebDAV). Scope, formats, out-of-scope: `docs/agents/product-positioning.md`.

### Vocabulary

**Glossary:** name domain concepts, discuss terminology, or edit an ADR → read **`GLOSSARY.md`** (definitions) and `docs/adr/` for decisions in that area. If output contradicts an ADR, say so explicitly. Read session page rendering → **`GLOSSARY.md`** **Page image fidelity** only (no duplicate rules elsewhere).

### Issues

GitHub Issues (`Zoti321/hentail_library`); use `gh`. Commands and triage labels: `docs/agents/issue-tracker.md`.

### Coding

Dart layers, widget state, Riverpod / MVVM: `docs/agents/coding-style.md`. Scan / sync / read / DB lives in Rust `core/`.

### UI

Single responsive shell, desktop Fluent-inspired, reuse `app/lib/shared/ui/widgets/`: `docs/agents/ui-style.md`.

### Testing

PR Gate vs local full suite, FRB thin-edge, UI dual-track: `docs/agents/testing.md`.

### Diagnostics

Collecting or exporting user logs, verbose diagnostics: `docs/agents/operations/log-support.md`.

### Tag dictionary

Importing curated tag JSON (not EhTag): `docs/agents/operations/tag-dictionary-import.md`.
