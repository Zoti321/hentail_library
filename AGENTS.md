# Hentai Library

Flutter lives in `app/`; Rust and FRB live in `core/`. Work in the current clone and branch; create a branch or worktree only with explicit user permission.

## Start here

- Setup and product scope: [README.md](README.md). Contributor commands and documentation map: [CONTRIBUTING.md](CONTRIBUTING.md).
- Domain vocabulary: [GLOSSARY.md](GLOSSARY.md). Read the relevant [ADRs](docs/adr/README.md) before changing a decision.
- Tests and CI: [gate.md](docs/engineering/gate.md). Local entry: `./scripts/run-gate.sh`; executable rules live in `app/test/gate/` and `app/test/architecture/`.

## Read for the task

- Dart layout, external adapters, core/shared ownership: [feature-data-layout.md](docs/engineering/feature-data-layout.md), ADR-0051/0052.
- Cross-feature calls, providers, events and composition: [cross-feature-collaboration.md](docs/engineering/cross-feature-collaboration.md), ADR-0034/0039/0050/0051.
- Domain ownership: [shared-domain-ownership.md](docs/engineering/shared-domain-ownership.md). Browse/comic/series seams: [library-browse-zones.md](docs/engineering/library-browse-zones.md).
- Domain type names: [ddd-domain-naming.md](docs/engineering/ddd-domain-naming.md). Reader names: [reader-ddd-lexicon.md](docs/engineering/reader-ddd-lexicon.md).
- Production UI: [design-system.md](docs/engineering/design-system.md), ADR-0053. The only external design-system entry is `app/lib/design-system/design_system.dart`. Product adapters belong to `shared/ui` or the feature owner.
- UI previews: `app/widgetbook/` (`cd app && flutter run -t widgetbook/main.dart`). Widgetbook is the Lab acceptance surface. The root `design-system/` directory is not a UI specification.
- Reader page rendering: **Page image fidelity** in GLOSSARY takes precedence over performance tuning advice.
- Rust sync, reading and persistence: `core/`, ADR-0002 and the relevant domain ADRs.
- Logs and tag dictionary support: [maintainer.md](docs/engineering/maintainer.md).
- Issue tracking: [issue-tracker.md](docs/agents/issue-tracker.md). Triage: [triage-labels.md](docs/agents/triage-labels.md). Domain documentation edits: [domain.md](docs/agents/domain.md).

## Documentation

Write agent instructions, engineering guides and GLOSSARY in English. Keep README files and CONTRIBUTING in Simplified Chinese. Preserve historical ADR decisions; add a superseding decision when behavior changes. Keep current procedures in engineering guides and task history in issues/PRs.

## File removal

Remove only one explicitly named file at a time. Recursive or bulk deletion is prohibited. If cleanup requires multiple deletions, stop that operation and ask the user to delete the files manually unless the user explicitly authorizes an exception.
