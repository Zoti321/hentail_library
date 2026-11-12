# Domain ownership and Shared Kernel

Follow ADR-0035/0041/0042/0045/0048/0049/0051/0052. New business types belong to their producer feature. Consumer count alone does not justify moving a type to shared.

## Owner rules

- Comic entity, metadata draft/locks, title projection, catalog rules and repositories: `features/comic/domain/`.
- Series entities, members, metadata and ordering rules: `features/series/domain/`. Public APIs expose queries/read-only records rather than the Series entity.
- Author/AuthorDetail/Tag and metadata dictionaries/forms: `features/comic_metadata/domain/`.
- Library configuration, credentials, sync/refresh and bulk-edit orchestration: `features/library_admin/`.
- Browse shell preferences and cross-tab query assembly: `features/library_browse/`; Comic/Series tab rules remain with their owners.
- Read sessions and reading preference semantics: `features/reader/`.
- Reading history and activity statistics: `reading_history` and `reading_stats` respectively; Home only assembles their presentation.
- Settings persistence/schema: `app_settings`; communicate Reader preferences through the primitive ReadingPreferencesRecord and Reader ACL (ADR-0046).
- Trash lifecycle and metadata backups: `comic_trash` and `metadata_backup` respectively.

Within a feature, import its own domain directly. Across features, use `public/**` only. Removed shared re-export shims are not compatibility surfaces. Current paths are discoverable in code; do not maintain a duplicate migration inventory here.

## Shared placement test

Keep a contract shared when importing its producer would violate a forbidden module edge or create a public cycle, or when shared code itself must consume it. Put domain vocabulary in `shared/domain/`, orchestration signatures in `shared/application/contracts/`, UI signatures/slots in `shared/ui/`, and Riverpod tokens in `shared/presentation/providers/`. Composition binds owner implementations. A contract's shared location does not transfer ownership of the business operation.

The Catalog Shared Kernel includes resource/display/thumbnail enums, pagination values, AuthorRef, SeriesItemMembership, SeriesReadingContext, shared age-restriction vocabulary and cover-source contracts. It excludes Comic/Series/Author entities and owner repositories. Domain events under `shared/domain/events/` are shared facts, not catalog entities.

## Transaction boundary

Rust owns the Comic aggregate write set: the Comic row, metadata/locks and facet junctions commit in one transaction (ADR-0002/0026). Dart Comic is a projection entity with construction invariants, draft application and field diffs. Do not duplicate Rust transactions, lock merging or rollback in a Dart aggregate. Single-Comic metadata writes and library-level sync/bulk/trash use their existing distinct write seams.

## Verification

Preserve `shared/domain`'s zero feature dependencies, public-only cross-feature edges, forbidden edges, acyclicity and required-provider binding. Entity ownership tests, module boundary tests and recursive dependency tests under `app/test/architecture/` and `app/test/gate/` enforce these rules. UI ownership follows [design-system.md](design-system.md), not this producer rule alone.
