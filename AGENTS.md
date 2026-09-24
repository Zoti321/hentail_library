## Agent skills

### Monorepo layout (Rust core)

The repo is a **monorepo**: Flutter lives under **`app/`**, Rust under **`core/`**. Root keeps `README.md`, `AGENTS.md`, `CONTEXT.md`, `docs/`, `.github/`. There is no Flutter `lib/` or `pubspec.yaml` at the repo root.

See **`docs/agents/rust-migration.md`** (current Rust/FRB architecture) and **`docs/adr/0002-rust-core-via-frb.md`**.

### Product positioning

Cross-platform comic reading & management app for a personal library (local folder roots and user-hosted WebDAV). Target formats: image dirs, comic archives (zip/cbz, rar/cbr, 7z/cb7), epub, pdf. See `docs/agents/product-positioning.md`. Read session pages follow **Page image fidelity** in `CONTEXT.md` (faithful source rendering outranks reader UI perf tweaks such as FilterQuality swing).

### Issue tracker

Issues live in GitHub Issues for this repo (`Zoti321/hentail_library`). See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical triage roles (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout: `CONTEXT.md` at the repo root and `docs/adr/` for ADRs. See `docs/agents/domain.md`.

### Coding style

Widget state: prefer `StatelessWidget` / `HookWidget` / `ConsumerWidget` / `HookConsumerWidget` over `StatefulWidget`. Lightweight pass-through data: prefer `typedef` + record over classes without serialization needs. Layer layout under **`app/lib/`**: `core/` (utilities), `domain/` (models; no use cases), `data/` (repositories → FRB), `ui/` — see `docs/agents/coding-style.md`. Business logic for scan/sync/read/DB lives in **`core/`** (Rust).

### UI style & responsive design

Reuse custom components from `app/lib/ui/core/widgets/`; follow desktop Fluent-inspired design language. Target: single responsive UI (desktop style wins); do not add new mobile-only Material pages. See `docs/agents/ui-style.md`.

### Testing

CI hard gates vs local full suite, FRB thin-edge contracts (not real FRB), UI dual-track, and shared test harness rules: `docs/agents/testing.md`.
