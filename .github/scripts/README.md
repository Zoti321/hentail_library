# CI scripts

Used only by GitHub Actions workflows (`gate.yml`, `nightly.yml`, `release.yml`). Not a local developer entrypoint.

- `run-gate.sh` — PR Gate / Release verify steps
- `run-rust-coverage.sh` — Nightly rust coverage
- `run-rust-fuzz.sh` — Nightly timed fuzz
- `run-rust-miri.sh` — Nightly filtered Miri
