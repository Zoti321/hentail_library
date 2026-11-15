# ADR-0057: Automatic Resource metadata embedding

## Status

Accepted. Implementation is tracked by the Resource metadata embedding issue family. This supersedes only the multi-value Language semantics and the absence of the newly supported Comic metadata scan sources in ADR-0007; its field-lock and nonempty scan-merge policies remain authoritative. The legacy language-list storage/wire shape remains compatible but contains at most one value.

> ADR-0058 supersedes only the Media page scope below: it delivers aggregate overview and Library opt-in settings, deferring individual Comic inspection.

## Context

User-edited Comic metadata currently remains in the catalog or a separate Metadata backup. Users need metadata to travel with original Local Resources and be recoverable on re-import. ComicInfo, EPUB package metadata and PDF XMP have different vocabularies and cannot faithfully express every application concept. Modifying original files also changes content evidence used by Path migration and cannot be atomic with a SQLite commit.

## Decision

- Resource metadata embedding is an opt-in Library property, default off and available only to Local libraries. Enabling it schedules existing visible Comics; subsequent direct and indirect user metadata changes schedule automatic writeback. There are no manual writeback or retry commands. Sync, Metadata refresh and lock-only changes do not schedule writeback.
- Rust owns durable pending work, revision-aware coalescing, automatic retries, source safety and recovery. Catalog saves remain successful when source writeback fails. Execution runs while the application is active and resumes after restart; closing the app does not imply a background daemon. Disabling a Library stops new executions while allowing an already-started safe replacement to finish.
- Use an anti-corruption layer with a small application-owned metadata interface and concrete format Adapters. Flutter and domain forms do not understand XML, OPF or XMP. Resource access remains read-only; local mutation is a distinct capability. Cross-feature composition respects ADR-0034/0045/0050/0051/0052, with no new umbrella owner for unrelated Library or Comic behavior.
- Implement writeback as a dedicated Rust `resource_metadata` module and a Flutter feature of the same name. The separate `media` feature composes metadata inspection, writeback state and existing editing capabilities through public interfaces. Comic and dictionary owners retain editing responsibility and register durable writeback intent; they do not own format serializers or the executor.
- Directories and comic archives use root ComicInfo metadata based on the 2.1 draft field set. EPUB uses its package metadata and PDF uses XMP. Standard properties are preferred; a versioned application extension carries otherwise lossy values, without database IDs, locks, reading history, Author links or Series management state. Valid supported extensions take precedence for the fields they explicitly encode when read by this application. External applications are only expected to understand standard properties.
- Preserve unknown fields and untouched values. Existing metadata receives sparse changed-field updates including explicit clears; creating metadata or enabling an existing Library writes the complete current snapshot. Fail on malformed or conflicting metadata instead of selecting or replacing it arbitrarily. Preserve existing creator-role fields other than the Writer projection when updating Authors; the application extension preserves the exact role-free Author list.
- Generate and verify replacement output before replacing a source; preserve page/content bytes and reading order. Detect source changes, prevent stale work from overwriting newer edits, and retain original files when safe processing is unavailable. Recover explicitly from the gap between file replacement and catalog observation updates. Reconcile Resource observations, probe baselines, content fingerprints and active Reader access under ADR-0026/0055 constraints; do not hold a database transaction over file I/O or block ordinary single-Comic editing with the Library write lock.
- Language is optional and single-valued. Migrate old lists by retaining the first stored value; preserve unrecognized imported values. Forms, bulk edits, backups and parsing follow the same cardinality.
- The Media page is reached from Home. Its first scope is Local Comic metadata and automatic-writeback state only, with Library/state filters, existing metadata editing, last successful writeback time and failure reasons. It does not scan source files to compare fields live. Its Library switch and Library form edit the same property. Library management and trash are future scope.
- ZIP/CBZ, directory, 7Z/CB7, EPUB and PDF support ship separately. RAR/CBR remain a target gated by an explicit feasibility/platform/licensing investigation; do not silently convert containers or claim unverified platform support.

## Alternatives and consequences

Manual export was rejected in favor of an automatic lifecycle. A single private format for all media was rejected in favor of interoperability through native standards plus versioned extensions. A synchronous filesystem operation inside a metadata transaction was rejected because failures must not undo catalog edits and source I/O cannot share SQLite atomicity.

This requires durable recovery and format-specific readback, not only serialization. A custom extension is a long-lived interoperability contract, so its versioning, clear semantics and malformed/unsupported-version fallback must be documented and tested before format delivery. Runtime status must distinguish disabled, pending, processing, completed, failed and unsupported resources; an unsupported resource is not a successful writeback.

## References

- [Parent specification #549](https://github.com/Zoti321/hentail_library/issues/549); child issues define staged acceptance and dependencies.
- ADR-0002, ADR-0007, ADR-0018, ADR-0026 and ADR-0055.
- [ComicInfo documentation](https://anansi-project.github.io/docs/comicinfo/documentation) and [2.1 draft schema](https://anansi-project.github.io/docs/comicinfo/schemas/v2.1).
- [W3C EPUB 3.3](https://www.w3.org/TR/epub-33/).
- [PDF Association: metadata streams](https://pdfa.org/resource/pdf-2-0-application-note-003-use-of-object-metadata-streams/).
- [RARLAB tools](https://www.rarlab.com/rar_add.htm) and [distribution terms](https://www.rarlab.com/license.htm).
