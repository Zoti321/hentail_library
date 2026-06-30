## Agent skills

### Monorepo layout (Rust migration)

The repo is moving to a **monorepo**: Flutter lives under **`app/`**, Rust under **`core/`**. Root keeps `README.md`, `AGENTS.md`, `CONTEXT.md`, `docs/`, `.github/`. Until the move lands, legacy paths may still be at the repo root — follow the parent GitHub issue for Rust FRB migration.

See **`docs/agents/rust-migration.md`** and **`docs/adr/0002-rust-core-via-frb.md`**.

### Product positioning

Cross-platform local comic reading & management app. Target formats: image dirs, comic archives (zip/cbz, rar/cbr, 7z/cb7), epub, pdf. See `docs/agents/product-positioning.md`.

### Issue tracker

Issues live in GitHub Issues for this repo (`Zoti321/hentail_library`). See `docs/agents/issue-tracker.md`.

### Triage labels

Triage labels are not used in this repo — do not create or apply `needs-triage`, `ready-for-agent`, or other triage role labels. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout: `CONTEXT.md` at the repo root and `docs/adr/` for ADRs. See `docs/agents/domain.md`.

### Coding style

Widget state: prefer `StatelessWidget` / `HookWidget` / `ConsumerWidget` / `HookConsumerWidget` over `StatefulWidget`. Lightweight pass-through data: prefer `typedef` + record over classes without serialization needs. Layer layout under **`app/lib/`**: `core/` (utilities), `domain/` (models; no use cases after migration), `data/` (repositories → FRB), `ui/` — see `docs/agents/coding-style.md`. Business logic for scan/sync/read/DB lives in **`core/`** (Rust).

### UI style & responsive design

Reuse custom components from `lib/ui/core/widgets/`; follow desktop Fluent-inspired design language. Target: single responsive UI (desktop style wins); do not add new mobile-only Material pages. See `docs/agents/ui-style.md`.
