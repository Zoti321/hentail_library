# ADR-0062: Image set discovery boundary

## Status

Accepted; supersedes the first-iteration Library root image set mapping recorded via #578 / #581

## Context

The first Image set delivery treated contentful first-level directories as Image sets and placed Library-root loose images plus root-level archive members into a synthetic **Library root image set**. That model conflicted with how illustration collections are usually laid out (standalone packages at the root as collections) and left unclassified root clutter inventing a special set. Product follow-up (#596) requires a clearer boundary without inventing a root set for ignored loose files.

## Decision

1. An **Image set** is either a first-level subdirectory of the Library root that yields discoverable images, or a first-level archive (zip/rar/7z and comic archive aliases) directly under the Library root.
2. Nested directories and archives under a **directory** Image set are physical carriers of that set's Image set images, not separate Image sets.
3. Loose image files directly under the Library root are **out of catalog** (ignored). Product documentation or in-app copy may explain the layout rule later; sync must not invent a Library root image set for them.
4. Observations that yield zero discoverable images do not create Image sets. A complete observation that a previously catalogued set is empty removes it under existing Image set sync deletion rules.
5. Incomplete carrier listing, inaccessible roots, cancellation and failed writes keep the conservative Image set sync semantics from the first delivery.

## Consequences

### Positive

- Root-level archives are first-class collections.
- Catalog kind stays distinct from Comic/Series without a synthetic unclassified set.
- Agents and docs can stop referring to Library root image set as current behavior.

### Negative

- Existing catalogs that stored a Library root image set will drop those rows (and root-archive members reappear as their own Image sets) on the next successful sync.
- Users who relied on root loose images in-catalog must move them into a first-level folder or archive.

## References

- #596 / #597
- GLOSSARY: Image set, Image set library, Image set sync
- Historical mapping: #578, #581 (first iteration)
