# ADR-0064: Image set workspace and resource mutation

## Status

Accepted

## Context

Image set sync today mirrors disk discovery into the catalog and derives in-set order from path natural sort. Product needs user order, curated submissions, optional disk mutation, and optional one-way managed layout without inventing a second catalog kind or a cross-set “virtual Image set.” Comic Resource metadata embedding (ADR-0057) is the wrong gate: it embeds Comic metadata into Local Resources, not Image set file layout.

## Decision

1. Keep ADR-0062 physical **Image set** boundaries. Logical management is an **Image set workspace** projection on that same set (no Workspace entity/ID).
2. Persist workspace **user order** and **Image set image exclude** on catalog rows. Default browse/Read use non-excluded members in user order. Sync reconciles existence only: it does not clear excludes, does not rewrite user order, and appends newly discovered images after existing order.
3. An **Image set submission** is an ordered membership subset inside one Image set (catalog-only). Members must be that set’s Image set images.
4. **Image set resource mutation** and **Image set managed layout** are per Local Image set library opt-ins, default off. Mutation off ⇒ add/remove are exclude/include only. Mutation on ⇒ directory sets may copy-in files or delete files on disk; no cross–Image set moves; root-archive sets unsupported. Managed layout rewrites a directory set to one first-level folder with images flattened and named by workspace order; takeover is one-way; submissions never become folders.
5. Do not reuse Resource metadata embedding APIs or vocabulary for these gates.

## Consequences

- Catalog schema and list/reader paths must honor user order and exclude before UI work.
- Agents must not treat “virtual Image set” as a catalog kind or allow cross-set aggregation.
- Closing mutation/managed layout stops further disk writes; it does not restore pre-takeover paths.

## References

- ADR-0062 (discovery boundary)
- ADR-0057 (Comic Resource metadata embedding — distinct)
- GLOSSARY: Image set workspace, Image set image exclude, Image set submission, Image set resource mutation, Image set managed layout
