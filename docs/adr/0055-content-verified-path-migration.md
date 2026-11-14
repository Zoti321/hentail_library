# ADR-0055: Content-verified Path migration

## Status

Accepted. Extends ADR-0054 with verified automatic rename/move continuity; weak-fingerprint-only matching remains prohibited. ADR-0001 location identity is unchanged.

## Context

Users need metadata and reading continuity after renaming or moving unchanged Resources. Type, size and page count cannot establish this. Full content evidence costs I/O, especially for WebDAV, but avoids speculative reassignment.

## Decision

Persist a versioned SHA-256 fingerprint during sync before a Resource can disappear. For ordinary files hash every byte, independently of filename or container format. For image directories hash all image bytes in Reader natural order, combining fixed-length page hashes and page count; exclude root paths and image names from the digest. Naturally equivalent filenames have no guaranteed reading order, so those directories receive no migration evidence.

Prepare fingerprints outside write transactions through ResourceAccess, including WebDAV. Reuse a file fingerprint at the same location only when resource type, positive modification time and size match its saved observation. Directories and files with unknown modification time are rehashed. This cache assumes source adapters accurately report changes; it is not proof against timestamp-preserving edits or a filesystem snapshot. Detect source changes and truncated reads during hashing and reject the scan. Check cancellation between read chunks and Resources.

Only a unique one-to-one removed/added digest match with the same resource type can trigger rekey. Changing the format interpretation is not an ordinary rename. Exact duplicate candidates remain ambiguous. Fingerprints are continuity evidence, never Comic IDs. Existing transaction-time metadata merges, locks, trash, history, Finished marks, covers and Series membership rekeys remain authoritative. Folder series inference retains whole-membership, common-parent and conflict checks.

Commit the fingerprint with the catalog, probe baseline and successful-sync metadata. Rekey it during explicit Local root remapping and cascade its removal with the Comic. An older record without a saved fingerprint cannot be retroactively matched once its source has disappeared.

## Consequences

Ordinary unchanged-file moves, including across storage volumes, regain automatic continuity. Initial hashing fully reads each Resource; WebDAV can require an entire download. Repacking, image re-encoding, page reordering and fuzzy matching are outside this decision. Directory pages must all be read on each sync because parent timestamps do not reliably describe child updates.
