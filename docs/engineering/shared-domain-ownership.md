# Domain ownership and Shared Kernel

Follow ADR-0035/0041/0042/0045/0048/0049/0051/0052. New business types belong to their producer feature. Consumer count alone does not justify moving a type to shared. Entity placement is enforced by `app/test/architecture/*_entity_ownership_test.dart`, module edges by `module_boundary_test.dart` and gate import contracts. Cross-feature call shape: [cross-feature-collaboration.md](cross-feature-collaboration.md). Sync/reader/metadata write paths: [rust-write-semantics.md](rust-write-semantics.md).

## Owners

| Feature | Owns |
|---------|------|
| `comic` | Comic entity, metadata draft/locks, title projection, catalog rules and repositories |
| `series` | Series entities, members, metadata and ordering; public APIs expose queries/read-only records, not the Series entity |
| `comic_metadata` | Author/AuthorDetail/Tag and metadata dictionaries/forms; merge-confirmation prefs and dictionary IO in infrastructure |
| `library_admin` | Library configuration, credentials, sync/refresh and bulk-edit orchestration |
| `library_browse` | Browse shell preferences and cross-tab query assembly; Comic/Series tab rules stay with owners |
| `reader` | Read sessions and reading preference semantics |
| `reading_history` / `reading_stats` | History and activity statistics; Home only assembles presentation |
| `home` | Library alert dismissal (domain values; JSON/persistence in infrastructure) |
| `app_settings` | Settings persistence/schema; Reader prefs via ReadingPreferencesRecord ACL (ADR-0046) |
| `comic_trash` / `metadata_backup` | Trash lifecycle and metadata backups |
| `image_set_library` | Image set catalog, workspace, submissions, catalog cover ensure/find and session cover cache |

Within a feature, import its own domain directly. Across features, use `public/**` only. Removed shared re-export shims are not compatibility surfaces.

Series planned count is absent or an integer from 1 through 2147483647; reject out-of-range before write and before FRB encoding (no silent wrap). Series metadata forms own validation and draft diffs; apply/persist use cases and Lab validators stay aligned with production rules.

## Shared placement test

Keep a contract shared when importing its producer would violate a forbidden module edge or create a public cycle, or when shared code itself must consume it. Put domain vocabulary in `shared/domain/`, orchestration signatures in `shared/application/contracts/`, UI signatures/slots in `shared/ui/`, and Riverpod tokens in `shared/presentation/providers/`. Composition binds owner implementations. A contract's shared location does not transfer ownership of the business operation.

The Catalog Shared Kernel includes resource/display/thumbnail enums, pagination values, AuthorRef, SeriesItemMembership, SeriesReadingContext, shared age-restriction vocabulary and cover-source contracts. It excludes Comic/Series/Author entities and owner repositories. Domain events under `shared/domain/events/` are shared facts, not catalog entities (ADR-0035/0039).

## Verification

Preserve `shared/domain`'s zero feature dependencies, public-only cross-feature edges, forbidden edges, acyclicity and required-provider binding. See [gate.md](gate.md). UI ownership follows [design-system.md](design-system.md).
