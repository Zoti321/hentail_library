# ADR-0059: Single nightly Dart test run

## Status

Accepted. Supersedes only the separate `nightly-dart-ui` job in ADR-0018.

## Decision

Run all `app/test` tests once in `nightly-dart-coverage` with coverage enabled. Its full test selection includes the UI paths previously run separately, so the extra job duplicated UI execution and toolchain setup without adding coverage. Keep the existing coverage artifact and summary, PR manifest, architecture and FRB boundary checks, and Watch platform integration tests.

This reduces nightly work at the cost of losing a separate UI job status; UI failures are reported by the full Dart test job. Current commands and manifest maintenance rules remain in [gate.md](../engineering/gate.md).
