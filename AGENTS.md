# Hentai Library

Flutter lives in `app/`; Rust and FRB live in `core/`. Work in the current clone and branch; create a branch or worktree only with explicit user permission.

## Start here

- Setup and product scope: [README.md](README.md). Contributor commands and documentation map: [CONTRIBUTING.md](CONTRIBUTING.md).
- Domain vocabulary: [GLOSSARY.md](GLOSSARY.md). Read the relevant [ADRs](docs/adr/README.md) before changing a decision.
- Tests and CI: [gate.md](docs/engineering/gate.md). Hard gates and Nightly run on GitHub Actions (`.github/scripts/`); executable rules live in `app/test/gate/` and `app/test/architecture/`.

## Read for the task

- Layout, public APIs, browse/comic/series shell, product seams: [cross-feature-collaboration.md](docs/engineering/cross-feature-collaboration.md), ADR-0034/0039/0050/0051/0052.
- Domain ownership and Shared Kernel: [shared-domain-ownership.md](docs/engineering/shared-domain-ownership.md). Sync/reader/metadata write paths: [rust-write-semantics.md](docs/engineering/rust-write-semantics.md), ADR-0002.
- Domain and Reader naming: [domain-naming.md](docs/engineering/domain-naming.md), ADR-0038/0061.
- Production UI: [design-system.md](docs/engineering/design-system.md), ADR-0053. The only external design-system entry is `app/lib/design-system/design_system.dart`. Product adapters belong to `shared/ui` or the feature owner.
- UI previews: `app/widgetbook/` (`cd app && flutter run -t widgetbook/main.dart`). Widgetbook is the Lab acceptance surface. The root `design-system/` directory is not a UI specification.
- Reader page rendering: **Page image fidelity** in GLOSSARY takes precedence over performance tuning advice.
- Logs and tag dictionary support: [maintainer.md](docs/engineering/maintainer.md).
- Issue tracking: [issue-tracker.md](docs/agents/issue-tracker.md). Triage: [triage-labels.md](docs/agents/triage-labels.md). Domain documentation edits: [domain.md](docs/agents/domain.md).

## Documentation

Write agent instructions, engineering guides and GLOSSARY in English. Keep README files and CONTRIBUTING in Simplified Chinese. Preserve historical ADR decisions; add a superseding decision when behavior changes. Keep current procedures in engineering guides and task history in issues/PRs.

## File removal

Remove only one explicitly named file at a time. Recursive or bulk deletion is prohibited. If cleanup requires multiple deletions, stop that operation and ask the user to delete the files manually unless the user explicitly authorizes an exception.
