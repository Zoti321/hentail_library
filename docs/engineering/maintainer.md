# Maintenance operations

## GitHub issues

Use `gh` inside the clone so the repository is inferred from its remote. The canonical tracker workflow is [issue-tracker.md](../agents/issue-tracker.md); state/category rules live in [triage-labels.md](../agents/triage-labels.md). Keep task history and individual verification results in issues/PRs rather than engineering guides.

## Diagnostics and support

Follow ADR-0004 and ADR-0010 for diagnostics and data-profile isolation.

1. Ask the reporter to enable verbose diagnostics in Settings, reproduce, then export logs (a redacted ZIP by default).
2. Inspect `app_log.txt`, `rust_log.txt`, `diagnostics.json` and rotated `.bak` files.
3. For UI jank, disable verbose diagnostics and use `flutter run --profile` with DevTools Performance.
4. For Rust development logging, use `RUST_LOG=hentai_core::sync=debug flutter run` from `app/` in a shell supporting environment prefixes.

Redaction shortens paths and hashes Comic IDs. Request full logs only when the path is necessary and the reporter chooses that export mode with the privacy confirmation.

## Tag dictionary import

ADR-0011 defines an idempotent import into the global Tag dictionary:

```json
{ "tags": ["tag-a", "tag-b"] }
```

A top-level string array is also accepted. Trim names, discard empty values, skip existing exact-name matches, and neither change/delete existing Tags nor attach them to Comics.

The metadata page's additional-actions menu accepts a local JSON file. Rust exposes `import_tag_dictionary`; Flutter's controller accepts bytes and also retains a network import capability. Use **Tag dictionary import** in issues/docs; EhTagTranslation is not a default data source.
