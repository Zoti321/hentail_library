## Agent skills

### Product positioning

Cross-platform local comic reading & management app. Target formats: image dirs, comic archives (zip/cbz, rar/cbr, 7z/cb7), epub, pdf. See `docs/agents/product-positioning.md`.

### Issue tracker

Issues live in GitHub Issues for this repo (`Zoti321/hentail_library`). See `docs/agents/issue-tracker.md`.

### Triage labels

Triage labels are not used in this repo — do not create or apply `needs-triage`, `ready-for-agent`, or other triage role labels. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout: `CONTEXT.md` at the repo root and `docs/adr/` for ADRs. See `docs/agents/domain.md`.

### Coding style

Widget state: prefer `StatelessWidget` / `HookWidget` / `ConsumerWidget` / `HookConsumerWidget` over `StatefulWidget`. Lightweight pass-through data: prefer `typedef` + record over classes without serialization needs. Layer layout: `core/` (utilities), `domain/`, `data/`, `ui/` — see `docs/agents/coding-style.md`.

### UI style & responsive design

Reuse custom components from `lib/ui/core/widgets/`; follow desktop Fluent-inspired design language. Target: single responsive UI (desktop style wins); do not add new mobile-only Material pages. See `docs/agents/ui-style.md`.
