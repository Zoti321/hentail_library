# Cross-feature collaboration

Authority for layers, public barrels, forbidden edges and acyclicity: ADR-0034/0039/0050/0051 plus `app/test/architecture/` and `app/test/gate/` (especially `public_interface_test.dart`, `module_boundary_test.dart`, `clean_architecture_dependency_test.dart`, `domain_event_rules_test.dart`, `project_layout_test.dart`). This guide only resolves placement ambiguity and product-seam gotchas. Ownership: [shared-domain-ownership.md](shared-domain-ownership.md). Naming: [domain-naming.md](domain-naming.md).

## Layout and adapters

`app/lib/` is organized by owner. Directory layout is the contract: `features/<owner>/{domain,application,infrastructure,presentation,public}/`, plus top-level `composition/`, `shared/`, `core/`, and feature-independent `infrastructure/`. Domain and application stay pure Dart through the full import graph. Do not reintroduce feature `data/` or `di/` layers. Presentation consumes injected contracts; required providers fail until composition supplies them.

Keep business adapters with their feature owner (`infrastructure/repositories|mappers|adapters|services`). Existing flat layouts remain valid.

| Concern | Placement |
|---------|-----------|
| SharedPreferences | Infrastructure only; owners expose typed repositories/commands; composition binds storage |
| Preference keys / migration markers | Owner adapter implementation details |
| Metadata import IO | Accept selected bytes or paths; no `File` / `PlatformFile` in contracts |
| PackageInfo | Infrastructure; installed-version query returns the version string via a shared FutureProvider |
| url_launcher | Infrastructure; owner command bound by composition; disposed widgets show no delayed feedback |

`core/` is product-independent pure Dart (no Flutter, Riverpod, `dart:io`, FRB or plugins). Shared placement rules: [shared-domain-ownership.md](shared-domain-ownership.md). Design-system entry: [design-system.md](design-system.md).

## Public surfaces and capabilities

`features/<owner>/public.dart` aggregates export-only facets: `contracts.dart`, `providers.dart`, `widgets.dart`. Use a narrow export when a broad barrel would pull UI into inner code. Factories and overrides stay in composition. `public/infrastructure/` is adapter-to-adapter only.

| Shape | Rule |
|-------|------|
| Command | Typed function; `ref.read(commandProvider)(...)` writes at call time only |
| Query | One-time read; do not replace fresh/session snapshots with an indefinitely cached FutureProvider |
| Continuous state | Owner StreamProvider/state Provider via `watch/select` |
| Committed fact | DomainEvent via DomainEventRevisions; `listen` reacts to state, is not a second bus |
| External IO | Keep meaningful Repository/NativeReader/ComicPageSource/Clipboard/sync contracts; add a Gateway only for real IO isolation |

Shared pure-Dart collaboration signatures: `shared/application/contracts/`. BuildContext signatures: `shared/ui/contracts/`. Tokens: `shared/presentation/providers/`. Domain facts: `shared/domain/events/`; bus implementation in `infrastructure/events/`.

Navigation: AppNavigator and AppRoutes; go_router stays with the routing host. `openReader` preserves its Future result. Shared ComicReadQuery and Series membership/reading-context contracts bridge forbidden edges. Progress/activity stay with reading_history/reading_stats.

## Browse, Comic and Series

ADR-0036: `library_browse` owns the current-Library shell, search, author details, query state and cross-tab UI assembly. `comic` / `series` own their rules and detail UX. List rows are read-only records (ADR-0040); Series does not expose its entity (ADR-0042).

Browse observes owner public providers one way; product modules do not read browse state back. Forbidden edges and baselines live in `module_boundary_test.dart` and gate import contracts — do not restate them here. Shared membership/reading-context contracts when an owner is unreachable. Do not hide a forbidden edge behind presentation bridges.

Browse preference values and the typed preferences repository contract live under `library_browse/domain/browse`. Notifiers keep optimistic UI and transient filters; they do not touch SharedPreferences keys. Independent field writes, default-key removal and legacy migrations stay in the owner adapter. Reset failures stay visible; do not overwrite unrelated dimensions with whole-preference saves. Shared page-size values live in `shared/domain/models/value_objects`; Series detail persists its own page size through injected commands. Rust owns catalog predicates and aggregate writes; browse assembles filter intent only.

## Product seams

| Topic | Owner | Contract tests (start here) |
|-------|-------|-----------------------------|
| Library load / form / registration | `library_admin` | `load_libraries_use_case_test.dart`, `submit_library_form_use_case_test.dart`, `library_repository_impl_test.dart`, `libraries_notifier_test.dart` |
| Library scan / interval | `library_admin` | `library_scan_domain_service_test.dart`, sync FRB adapter tests |
| Metadata backup / import | `metadata_backup` | `run_metadata_auto_backup_use_case_test.dart`, `prepare_metadata_import_use_case_test.dart`, `metadata_backup_preferences_test.dart`, `metadata_auto_backup_coordinator_test.dart` |
| Tag dictionary / named metadata | `comic_metadata` | `import_tag_dictionary_use_case_test.dart`, `named_facet_management_service_test.dart` |
| Comic metadata edit / Smart facet | `comic` | `apply_comic_metadata_form_use_case_test.dart`, `save_comic_metadata_use_case_test.dart`, `comic_metadata_edit_session_notifier_test.dart`, `load_comic_smart_facet_candidates_use_case_test.dart` |
| Trash | `comic_trash` | `comic_trash_service_test.dart` |
| Settings / app update | `app_settings` | `settings_notifier_test.dart`, `check_app_update_use_case_test.dart`; appearance enum checklist in `app/lib/features/app_settings/README.md` |
| Read session / prefetch / chrome / cover | `reader` | `open_read_session_use_case_test.dart`, `manage_read_session_use_case_test.dart`, `reader_prefetch_notifier_test.dart`, `reader_chrome_notifier_test.dart`, `reader_cover_editor_notifier_test.dart` |
| History feed | `reading_history` | `history_paged_feed_controller_test.dart` |

### Gotchas

| Situation | Do |
|-----------|-----|
| Library deletion vs WebDAV credentials | Delete credentials only after core catalog deletion succeeds. Busy/DB failure keeps credentials and the original core error. Credential cleanup failure after catalog commit propagates without compensating the deletion. |
| Remote Library registration | Idempotent by normalized root; returned identity does not prove this call created it. Password-save failure after core registration preserves the catalog and propagates the credential error — do not delete the Library as compensation. |
| Library form catalog/access kind | Derive from the saved Library. Image set → Local-only, no Comic format multi-select. Draft flags cannot change catalog/access kind. |
| Accepted writes vs UI lifetime | Form/deletion/backup/settings/history/trash commands retain owner results after disposal; presentation alone decides refresh. Older list/query/refresh generations must not overwrite newer ones. |
| Partial commits | A later failure must not silently retry or compensate an earlier successful write (Library commands, Comic metadata then Series order, trash purge, tag import, cover commands). |
| Library scan runs | Each invocation owns cancellation and completion; earlier run progress cannot publish success for the current run. |
| Auto-backup coordinator | Wait for persisted preferences before enabling; do not fall back to enabled with no previous backup. Completion records through the captured repository, not a UI Notifier. |
| Reader session open | Lifetime keyed by `sessionKey`; late results must not restore an obsolete cache. Image set uses `ImageSetReadPort`. Consume `ReadSessionCapabilities` rather than catalog-kind branches. |
| Native Reader session/cache | Opaque session snapshots and request identities; obsolete clear/prefetch/decode must not refill or release a newer barrier. Details live with Reader/Rust tests and [rust-write-semantics.md](rust-write-semantics.md) for catalog writeback. |

## Verification

Run affected architecture/gate tests and the feature contract tests linked above. See [gate.md](gate.md).
