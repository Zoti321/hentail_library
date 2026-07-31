# unrar-ng-sys (patched)

Vendored from crates.io `unrar-ng-sys` 0.7.7 with patches for mobile cross-compiles:

1. **`build.rs`**: select Windows-only sources / link libs using `CARGO_CFG_TARGET_OS` (target), not host `cfg!(windows)`.
2. **`vendor/unrar/ulinks.cpp`**: skip `lutimes` on Android (`UNRAR_NG_ANDROID` / `__ANDROID__`).

Wired via `[patch.crates-io]` in `core/Cargo.toml`.
