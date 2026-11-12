# Tests and CI

ADR-0018 defines the test seams. Rust owns sync/read/database business truth (ADR-0002). `.github/workflows/gate.yml` owns the PR job list and SDK/codegen versions; `scripts/run-gate.sh` supplies the same commands locally and in CI.

## Run checks

From the repository root, run `./scripts/run-gate.sh` for all hard gates, or pass relevant steps:

```bash
./scripts/run-gate.sh rust-lint rust-test
./scripts/run-gate.sh dart-static dart-lint dart-test
./scripts/run-gate.sh codegen-drift
```

Use `./scripts/run-gate.sh --help` for step details. `dart-test` first builds the host hentai_flutter cdylib, then runs `app/test/gate/manifest.txt`. `codegen-drift` regenerates FRB/build_runner outputs in place and compares all tracked/untracked changes under app/core with HEAD; commit relevant work before running it. Use a local SDK aligned with CI; CI treats analyzer info diagnostics as failures.

For focused Flutter checks, run `flutter test <path>` from `app/`. For full UI regression checks, run `flutter test` after building the host cdylib. Regenerate localization with `flutter gen-l10n` when ARB inputs change. Platform smoke tests under `integration_test/` use `*_smoke_test.dart`, run through Watch/Release, and stay outside the hard manifest. Sync/WebDAV end-to-end business tests belong in Rust.

## Test seams and harnesses

- Rust business/DB tests: `core/crates/core/tests/`, shared harness `tests/common/`.
- FRB wire contracts: `app/test/frb_wire/`; the harness finds the host cdylib in `core/target/{debug,release}` or `HENTAI_FLUTTER_LIB`.
- Dart thin edges: owner domain/application/infrastructure, mappers, guards and injected capabilities. Do not repeat Rust business flows against real FRB repository implementations.
- Observable UI contracts: use `test/support/pump_localized_app.dart` (pumpLocalizedApp) for product UI; `pump_design_system_app.dart` for independent design-system components. Existing `pumpApp`, fakes and `configureTestView` cover host/provider/view setup. Avoid copying MaterialApp/localization boilerplate; calendar tests may need their specialized localization host.

## Manifest and nightly

`app/test/gate/manifest.txt` is the single fast-track selection source; `manifest_test.dart` checks paths and duplication. Promote a test only when it asserts an observable contract, uses the shared harness, and passes three consecutive focused runs. Inject time when needed. Add its path to the appropriate manifest section and list additions in the PR; do not add another workflow.

The inventory's slow track is every test outside the expanded manifest. Nightly's UI job actually runs `test/shared/ui` and `test/features`; those directories overlap the fast track and do not cover every possible non-manifest path. Nightly also collects full Dart coverage and hentai-core Rust coverage; see `.github/workflows/nightly.yml`. Do not describe it as an exact manifest complement.

```bash
python scripts/audit_dart_tests.py --summary-json
python scripts/audit_dart_tests.py --json
python scripts/audit_dart_tests.py --rubric candidate-retire --slow-only
python -m unittest discover -s scripts -p test_audit_dart_tests.py
```

The rubric is an audit heuristic, not permission to delete tests: architecture-guard protects structural rules, thin-edge protects adapter/contract seams, ui-contract covers observable behavior, candidate-retire flags slow-track files for review. The script reports live counts; do not copy count snapshots into this guide.

Demotion requires a PR listing each path, rubric and reason, plus manifest/self-test updates. Protect architecture/layout, FRB wire, thin-edge and minimum App/Lab smoke coverage unless paired with the corresponding rule/ADR migration. Keep a demoted test until a successful focused run or nightly validates it; retire it in a later PR linked to that decision. Check actual nightly path selection before claiming coverage. Moves retain existing assertions and fast-track coverage.

## DCL

`dart-lint` runs dart_code_linter on `app/lib`; generated files are excluded. Every diagnostic severity fails. `app/analysis_options.yaml` owns rules and the `rules-exclude` ratchet: exemptions only shrink. Fix a legacy file, remove its exemption, then rerun dart-lint. Enable a new rule only after a clean local run. Metrics are currently outside the hard gate.

Keep DCL out of top-level analyzer plugins to avoid duplicate/fatal analyzer diagnostics; riverpod_lint is not enabled in the Gate analyzer configuration. Deliberately excluded rules include non-ASCII/comment punctuation requirements (Chinese source text), trailing commas (formatter conflict), newline-before-return (format churn), and prefer-first-or-null (conflicts with prefer-first). Rules requiring mandatory configuration remain disabled until configured.

DCL's installed rule implementation may be smaller than its presets; validate new rule names with `dart run dart_code_linter:metrics analyze lib -c`. The current DCL fixer can corrupt overlapping replacements: apply at most one rule at a time, inspect the diff and verify Dart formatting/parsing afterward.

## Architecture checks

Run affected tests from `app/`; current rules and baselines are the source of truth:

- `test/project_layout_test.dart`: allowed directories and module structure.
- `test/gate/import_boundary_test.dart`, `test/architecture/module_boundary_test.dart`: public-only/forbidden edges, import/export graphs, acyclicity and shrink-only baselines.
- `test/architecture/clean_architecture_dependency_test.dart`, `dart_dependency_graph_test.dart`: recursive core/inner-layer purity and composition direction, including third-party runtime dependencies and scanner bypass regressions.
- `test/architecture/public_interface_test.dart`, `test/gate/shared_di_override_coverage_test.dart`: export-only public surfaces and required-provider binding.
- Entity ownership, slot, navigation and `test/gate/shared_*_no_feature_import_test.dart` checks: preserve owner and shared boundaries.
- `test/gate/domain_event_rules_test.dart`: shared event vocabulary, permitted publishers and one bus implementation.
- `test/design-system/design_system_boundary_test.dart`, `design_system_dependency_policy_test.dart`: independent UI dependencies and the sole explicit public entry.

Regenerate a boundary baseline only for an intentional, reviewed architecture change; remove stale entries rather than expanding an exemption to make a move pass. See [layout](feature-data-layout.md), [collaboration](cross-feature-collaboration.md) and [design system](design-system.md) for the relevant decisions.
