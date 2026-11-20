# Tests and CI

ADR-0018 defines the test seams. Rust owns sync/read/database business truth (ADR-0002). `.github/workflows/gate.yml` owns the PR job list and SDK/codegen versions. Hard gates, Nightly coverage/fuzz/miri, and Release verify run only on GitHub Actions via [`.github/scripts/`](../../.github/scripts/).

## Run checks

There is no local gate wrapper. Rely on GitHub Actions (`Gate`, `Nightly`, `Release`) for the authoritative suite. For focused local work:

- Rust: `cargo fmt` / `cargo clippy` / `cargo nextest` under `core/` (nextest profile `ci` matches Gate).
- Dart: `dart format`, `flutter analyze`, and `flutter test <path>` from `app/` after building the host `hentai_flutter` cdylib when FRB wire tests need it.
- Codegen: regenerate FRB / `build_runner` when you change bindings; Gate's `codegen-drift` job fails on uncommitted drift.

Nightly runs timed fuzz and filtered Miri (nightly toolchain) through `.github/scripts/`. Release cdylib size notes: [rust-binary-size.md](rust-binary-size.md).

Regenerate localization with `flutter gen-l10n` when ARB inputs change. Platform smoke tests under `integration_test/` use `*_smoke_test.dart`, run through Watch/Release, and stay outside the hard manifest. Sync/WebDAV end-to-end business tests belong in Rust.

## Test seams and harnesses

- Rust business/DB tests: `core/crates/core/tests/`, shared harness `tests/common/`.
- FRB wire contracts: `app/test/frb_wire/`; the harness finds the host cdylib in `core/target/{debug,release}` or `HENTAI_FLUTTER_LIB`. Wire smoke databases remain in the OS temporary directory (`frb_wire_*`) for manual cleanup, following the repository's file-removal policy.
- Dart thin edges: owner domain/application/infrastructure, mappers, guards and injected capabilities. Do not repeat Rust business flows against real FRB repository implementations.
- Observable UI contracts: use `test/support/pump_localized_app.dart` (pumpLocalizedApp) for product UI; `pump_design_system_app.dart` for independent design-system components. Existing `pumpApp`, fakes and `configureTestView` cover host/provider/view setup. Avoid copying MaterialApp/localization boilerplate; calendar tests may need their specialized localization host.

## Manifest and nightly

`app/test/gate/manifest.txt` is the single fast-track selection source; `manifest_test.dart` checks paths and duplication. A directory entry includes all tests below it; do not also list its descendants. Promote a test only when it asserts an observable contract, uses the shared harness, and passes three consecutive focused runs. Inject time when needed. Add its path to the appropriate manifest section and list additions in the PR; do not add another workflow.

The inventory's slow track is every test outside the expanded manifest. Nightly's `nightly-dart-coverage` job runs all `app/test` tests once with coverage, including both fast and slow tracks. ADR-0059 replaces the separate `nightly-dart-ui` run described in ADR-0018; no UI assertions are dropped. Nightly also collects hentai-core Rust coverage; see `.github/workflows/nightly.yml`. Platform integration tests remain in Watch and are outside this Dart coverage run.

When reviewing slow-track tests, treat rubrics as heuristics only (not permission to delete): architecture-guard for structural rules, thin-edge for adapter/contract seams, ui-contract for observable behavior, candidate-retire for slow-track files that may be demoted after review. Prefer real contract assertions over compile-smoke checks that only assert imported symbols with `isNotNull`.

Demotion requires a PR listing each path, rubric and reason, plus manifest/self-test updates. Protect architecture/layout, FRB wire, thin-edge and minimum App/Lab smoke coverage unless paired with the corresponding rule/ADR migration. Keep a demoted test until a successful focused run or nightly validates it; retire it in a later PR linked to that decision. Check actual nightly path selection before claiming coverage. Moves retain existing assertions and fast-track coverage.

## Dart analysis

The package analysis options inherit Flutter's recommended lints, enable strict
casts, inference and raw types, and check discarded/unawaited futures. Context
usage across asynchronous gaps and deprecated API diagnostics are not globally
suppressed. Await dependent work, return its future, or explicitly mark independent
work with `unawaited`; the latter does not handle errors. Preserve the existing
error recipient or add one at the owning boundary when needed.

Riverpod lint runs as a top-level analyzer plugin through `dart-static`, using the
version declared in the analysis options. Keep it compatible with the dependency
and CI SDK. Plugin ignores use the `riverpod_lint/` diagnostic prefix and must be
local with an adjacent reason. Existing exceptions cover imperative edit/cursor
observations, test fixture instrumentation, bootstrap scopes hidden behind host
widgets, and deliberate short-lived reads/subscriptions. They do not authorize
blanket exceptions for new code or extending provider lifetimes to silence lints.
UI context and image decoding stay in UI adapters; providers receive callbacks.

Analyzer still checks generated code for type errors. FRB 2.13 emits an opaque
`RustArcStaticData` without inferable generic arguments. Its generator preamble
suppresses only `inference_failure_on_instance_creation` in generated FRB output;
remove that workaround when the generator supplies the type. Do not hand-edit
generated output or exclude all generated files from Analyzer.

## DCL

`dart-lint` runs dart_code_linter on production and tests in one CLI invocation;
generated files are excluded. Every diagnostic severity fails. The single package analysis
options file owns all rules. Per-rule `include` patterns keep production rules
on `lib/**`, assertion/file-name rules on `test/**`, and private-test-declaration
rules on `test/**/*_test.dart` (shared support helpers stay importable). This keeps Widget organization
rules out of test fixtures without disabling test lint coverage. The registered
color assertion helper performs actual channel assertions, rather than bypassing
the missing-assertion rule. The shared `rules-exclude` list stays empty; exemptions
may only shrink. Enable a new rule only after a clean local run. Metrics are
currently outside the hard gate.

Keep DCL out of top-level analyzer plugins to avoid duplicate/fatal analyzer
diagnostics. Deliberately excluded rules include non-ASCII/comment punctuation
requirements (Chinese source text), trailing commas (formatter conflict),
newline-before-return (format churn), and prefer-first-or-null (conflicts with
prefer-first). Rules requiring mandatory configuration remain disabled until
configured. Existing Widget-factory name exceptions implement route, composition
slot or Settings section callback contracts. DCL matches names, not owners: audit
all matching declarations when adding or renaming a function, remove stale names,
and do not reuse an exempt name to bypass the rule.

DCL's installed rule implementation may be smaller than its presets; validate new rule names with `dart run dart_code_linter:metrics analyze lib -c`. The current DCL fixer can corrupt overlapping replacements: apply at most one rule at a time, inspect the diff and verify Dart formatting/parsing afterward.

## Architecture checks

Run affected tests from `app/`; current rules and baselines are the source of truth:

- `test/project_layout_test.dart`: allowed directories and module structure.
- `test/gate/import_boundary_test.dart`, `test/architecture/module_boundary_test.dart`: public-only/forbidden edges, import/export graphs, acyclicity and shrink-only baselines.
- `test/architecture/clean_architecture_dependency_test.dart`, `dart_dependency_graph_test.dart`: recursive core/inner-layer purity, including third-party runtime dependencies; outer-layer direction through application import/export/part graphs, with conditional-branch and scanner bypass regressions. Violations report the dependency chain from the original consumer.
- `test/architecture/public_interface_test.dart`, `test/gate/shared_di_override_coverage_test.dart`: export-only public surfaces and required-provider binding.
- Entity ownership, slot, navigation and `test/gate/shared_*_no_feature_import_test.dart` checks: preserve owner and shared boundaries.
- `test/gate/domain_event_rules_test.dart`: shared event vocabulary, permitted publishers and one bus implementation.
- `test/design-system/design_system_boundary_test.dart`, `design_system_dependency_policy_test.dart`: independent UI dependencies and the sole explicit public entry.

Regenerate a boundary baseline only for an intentional, reviewed architecture change; remove stale entries rather than expanding an exemption to make a move pass. See [collaboration](cross-feature-collaboration.md), [ownership](shared-domain-ownership.md) and [design system](design-system.md) for the relevant decisions.

## Core consistency regressions

Run `cargo test -p hentai-core --test content_path_migration --test comic_metadata_bulk_patch --test path_migration_sync_test --test series_path_migration_sync_test --test scan_commit_metadata --test sync_coherent_commit --test update_local_library_root` from `core/` for the transactional metadata, conservative migration, coherent sync and Reader invalidation seams. These fixtures are retained for manual cleanup. Reader lifetime and decode isolation regressions are selected with `cargo test -p hentai-core --lib reader::manager::tests`, `reader::page::` and `reader::prefetch::`.

Library sync permits unique full-content fingerprint matches (ADR-0055), while rejecting weak-fingerprint-only automatic rekeys (ADR-0054). Unverified or ambiguous renames follow orphan removal plus new import. Initial hashing fully reads Resources, including WebDAV downloads; file hashes are cached by source observations and image directories are rehashed. Old records must first sync at their existing location to establish content evidence. Explicit Local root remapping retains its separate eligibility checks. Sync prepares resource observations before opening its write transaction, then commits catalog reconciliation, probe baseline and success metadata together. Reader invalidation precedes revision publication and thumbnail queue follow-up. Thumbnail maintenance errors use the existing progress warning and failed-thumbnail fields without implying rollback of committed catalog state.
