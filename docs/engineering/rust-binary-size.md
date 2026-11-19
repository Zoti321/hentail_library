# Rust binary size (FRB cdylib)

Workspace release settings live in [`core/Cargo.toml`](../../core/Cargo.toml). Flutter **profile** builds map to Cargo **release** via Cargokit.

## Release profile knobs

Current defaults:

| Setting | Value | Why |
|---------|-------|-----|
| `opt-level` | `"s"` | Prefer size; keep loop vectorization (unlike `"z"`) for decode paths |
| `lto` | `"thin"` | Cross-crate dead-code removal with acceptable link time; try `"fat"` if size still dominates |
| `codegen-units` | `1` | Better optimization at the cost of slower release builds |
| `strip` | `true` | Strip symbols from the final artifact |
| `panic` | `"abort"` | Drop unwind tables in the cdylib |

Dev profile keeps `debug = "line-tables-only"` and `strip = "debuginfo"` so Android debug APKs do not ship a ~200MB `libhentai_flutter.so`.

## What counts toward APK / App size

Per enabled Android ABI (and similarly for other platforms):

1. `libhentai_flutter.so` — Rust monolith (`hentai-core` + FRB)
2. `libpdfium.so` / `libpdfium.dylib` — **vendored dynamic** library (not linked into the Rust `.so`; ~3MB per iOS slice historically)
3. `libc++_shared.so` — required by statically linked UnRAR C++

Multi-ABI packaging multiplies native footprint roughly linearly. Cargokit debug builds also include emulator x86/x64 ABIs.

## Measuring

Host ELF baseline (install `cargo-bloat` first):

```bash
mkdir -p core/target/bloat
cargo bloat --manifest-path core/Cargo.toml -p hentai_flutter --release --crates \
  | tee core/target/bloat/hentai_flutter-crates.txt
cargo bloat --manifest-path core/Cargo.toml -p hentai_flutter --release -n 40 \
  | tee core/target/bloat/hentai_flutter-functions.txt
```

Optional Android NDK cross analysis needs a local NDK toolchain and is not required for the host baseline. Size checks are not a local gate script; fold them into CI when automated.

## Likely size offenders (concept order)

Do not drop format support solely for size. Use bloat reports before feature-gating:

1. Monolith cdylib: SeaORM / Tokio / HTTP / all archive formats
2. Static UnRAR C++ (`unrar-ng`) plus packaged `libc++_shared`
3. Dual SQLite stacks: `sea-orm`/`sqlx-sqlite` and `rusqlite`
4. `image`, `sevenz-rust`, `zip`, `lopdf`
5. `reqwest` + `reqwest_dav` + rustls
6. Per-ABI vendored pdfium

## Related

- [`core/vendor/README.md`](../../core/vendor/README.md) — pdfium fetch and link strategy
- [ADR-0015](../adr/0015-ios-pdf-via-vendored-pdfium.md) — iOS pdfium embedding
- [`gate.md`](gate.md) — Rust gate commands
