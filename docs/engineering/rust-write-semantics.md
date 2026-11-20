# Rust write semantics

Read this when changing Library sync, Reader first-open writeback, Metadata refresh, Comic persistence upsert/delete, Series folder-name refresh, reading activity/history commits, NamedFacet deletion notify, or bulk published-date encoding. Dart ownership of projections is in [shared-domain-ownership.md](shared-domain-ownership.md). Decisions: ADR-0002/0006/0013/0026.

## Comic aggregate

Rust owns the Comic aggregate write set: the Comic row, metadata/locks and facet junctions commit in one transaction. Dart Comic is a projection entity with construction invariants, draft application and field diffs. Do not duplicate Rust transactions, lock merging or rollback in a Dart aggregate. Single-Comic metadata writes and library-level sync/bulk/trash use their existing distinct write seams.

Rust `comic` owns the internal full upsert and deletion write sets in `comic/persistence.rs`. Both accept the caller's `DatabaseTransaction`; callers retain commit, notification, library locking and resource I/O. Reader writeback, Metadata refresh, Library deletion and scan maintenance use these Comic entry points. Sync owns scan-plan application and Series rebuilding, rather than the reusable Comic persistence implementation. Comic metadata patches call the Author and NamedFacet owners directly for facet replacement.

## Library sync and resources

Library sync plans retain source candidates and distinguish Resource metadata from reused catalog projections. Planning may derive thumbnail candidates, but those projections are not persistence payloads. Thumbnail fingerprint reads for sync planning (`source_modified_ms` / `source_size`) must use column projection only and must never `SELECT` the thumbnail BLOB. The scan writer loads the current complete Comic aggregates inside its transaction, then merges source metadata against current values and locks. Reuse updates physical fields while preserving current metadata, locks and page count; it cannot insert a missing catalog record. Expected existing identities that disappeared invalidate the plan before any writes. Planned Comic migrations also retain scan candidates and become persistence migrations only after this merge. Their current metadata and locks accompany live child attachments and trash state to the new identity. The transaction still covers the whole Library write set, with one notification after commit and no automatic retry.

Resource parsing derives identity, filename title fallbacks and size from the original location and its ResourceAccess adapter. RAR/CBR, 7z/CB7 and PDF decoders receive the adapter's local path when available; otherwise parsing holds a temporary file for the duration of native decoding. URL prefixes do not select the I/O implementation, and temporary filenames or local decoder paths do not become catalog metadata. Source stat failures propagate and missing or non-file sources are not imported. PDF embedded metadata retains precedence over filename fallbacks.

Resource owns the file/directory parse dispatch used by Library sync and explicit Metadata refresh, using the adapter's actual kind. A qualifying image directory remains a directory even when its name ends in a supported file extension. Explicit directory refresh recomputes image count, total size and the folder title under the existing field locks; mixed or nested folders retain their existing rejection rules. Reader directory page-list reconciliation uses the opened session's page count and does not parse directory contents again, including for names with file extensions.

## Library removal and Series rebuild

Library removal acquires the existing global Library write lock before reading or deleting catalog records. It fails immediately while sync, refresh or another bulk write owns that lock, preventing an in-progress scan from recreating records for a removed Library. The Library, Comic write sets, Series and resource snapshots retain their existing single transaction; failure rolls back without notification and releases the lock. Removal deletes records while retaining Resources.

Folder series rebuilding captures members' locked sort orders before deleting inactive Series or clearing memberships. Deleting a source Series cascades to its memberships, including the last Comic moved into an existing target Series; this cleanup must not erase that Comic's manual order or lock before the target membership is rebuilt (ADR-0006/0013).

## Reader writeback and Metadata refresh

Reader first-open physical metadata writeback follows the same single-Comic transaction rule. Resource parsing precedes the transaction and validates the source metadata retained by the Reader snapshot before and after I/O. Within the transaction, Comic's repository loads the latest visible aggregate, and Reader checks its path, type, Library and catalog size before merging against its current field locks. Missing, trashed or changed sources are skipped; a parse without metadata changes only the latest aggregate's page count. The Comic row, metadata and facet replacements commit together before notifying observers. The internal Comic upsert accepts a database transaction rather than an autocommit connection. This write does not acquire the global Library write lock. Failed or skipped writes do not announce a commit. Reader page-list loading remains usable when this best-effort writeback fails, with the failure logged by the existing reader entry point. Source metadata validation and the database commit are separate operations, rather than an atomic filesystem/database transaction.

Explicit Metadata refresh also parses outside the transaction and merges against the latest visible Comic and field locks inside it. It validates source metadata after parsing and checks path, type, Library and catalog size again before writing. A missing, trashed or changed source fails that Comic without notification or retry; Series and Library refresh retain committed members and continue reporting partial failures. Batch target selection excludes Comics already in trash. The global Library write lock still guards refresh orchestration, while single-entity user edits remain available.

## Series name refresh

Series owns folder-derived name refresh through its internal write command. After member refresh, the command uses the caller's database connection and reads the current folder, name and name lock in its own transaction. It updates only the name and sort key and notifies once after an actual committed change, including a Series with no members. A newly locked user name is retained, a newly released lock permits inference, and unchanged or failed writes do not notify. Refresh checks cancellation before entering the name phase and before each Library name write, including after the last member and for empty member lists. Cancellation skips remaining writes; an already accepted transaction may finish.

## Reading activity, history and facets

Reading activity commands commit their duration increment and optional Finished comic mark in one Rust transaction, then notify observers once. A failure in either write rolls back the complete command without notification or automatic retry. Shared SQL helpers use the caller's connection so the combined command and existing single-action APIs retain the same positive-duration and sticky first-finished-time rules. Dart still owns session qualification, incognito handling and last-page semantics; this write does not acquire the library write lock.

Reading history commands commit the per-Comic progress upsert and expired-history retention cleanup in one Rust transaction, then notify observers once. A retention failure restores the previous title, last-read time and page, or leaves a new history absent, without notifying observers. Sync continues to run the same retention helper inside its own transaction. History writes retain their existing timestamp replacement semantics and remain independent of Reading activity statistics.

NamedFacet dictionary deletion notifies revision subscribers once after its SQL statement succeeds, including non-empty requests whose names are already absent. Empty requests and failed SQL do not notify. Tag, Parody and Character deletion share this owner path; observers must not rely on a presentation refresh to discover the committed change.

Reading activity snapshots load the Finished comic count and lifetime duration in one SQL statement. Finished marks count only when their Comic exists and is not trashed; orphan-history visibility does not apply to this metric. A missing duration singleton yields zero duration while retaining the visible finished count.

## Bulk published date

Bulk published-date requests distinguish a replacement containing a valid DateTime from explicit clearing. Timestamp encoding belongs to the library_admin FRB mapper; epoch zero is a valid replacement, never a fallback for missing input. The Comic editor retains raw input and blocks confirmation when a selected replacement has no parseable date. Unselected fields stay absent, and other selected edits are not submitted while that replacement is invalid.
