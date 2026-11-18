# ADR-0061: Multi-source Read session and Capabilities

## Status

Accepted; partially supersedes ADR-0005 session-entry wording (comicId-only) while preserving Comic progress and Series-context rules

## Context

ADR-0005 unified Comic Read sessions around `comicId`, Reading history, and derived Series reading context. Image set libraries later open the same Reader product module through `ReadSessionSource`, but the implementation reused `ReaderComicRef` / `comicId` and gated Comic-only behavior with scattered `isImageSet` / `image_set:` string checks. That fake polymorphism leaks catalog kind into presentation and makes a third source harder.

Shared needs (viewport, chrome/fullscreen, page fidelity, single-session auto-play, page copy) must stay one shell. Comic-only needs (history/stats, Series navigation, cover actions, native archive session/prefetch, go_router exit) must be explicit capabilities, not catalog-kind branches.

## Decision

1. A **Read session** opens from a sealed `ReadSessionSource` (Comic or Image set). Comic entry, progress, and Series context retain ADR-0005 rules. Image set entry uses open parameters (index or Image set image identity) for the start page and never writes Reading history or reading_stats.
2. Domain owns `ReadSessionCapabilities` derived from source (and incognito). Application and presentation consume capability flags; they do not branch on catalog kind or parse `image_set:` session-key prefixes as business logic.
3. Domain owns `ReadSessionSubject` as the session display header (`sessionKey`, title, pageCount). `ReaderComicRef` remains the Comic-only narrow model for native Comic page IO (`NativeReaderPort` / `ComicPageSourcePort`).
4. Reader stays one product module with capability slots (progress, Series nav, cover actions, exit policy). Do not split Comic/Image set into separate Reader features.
5. Page list and page-byte providers are keyed by `ReadSessionSource` (or its `sessionKey` with an opened source snapshot), not by a Comic-shaped disguise.

## Consequences

### Positive

- Shared shell stays testable; Comic-only features compose in without Image set special cases in views.
- Glossary, lexicon and code agree that Read session is multi-source while progress remains Comic-only.
- Removing the `image_set:` string protocol reduces cache-miss open bugs and false Comic opens.

### Negative

- Migrating providers, view models and open orchestration is a multi-phase refactor with temporary forwarding aliases.
- Call sites that still hold only a string session key must retain an opened source/capabilities snapshot.

## References

- ADR-0005 (Comic progress / Series context; entry wording superseded here)
- ADR-0038 (Reader product module)
- ADR-0060 (Page image fidelity for Comic and Image set)
- `docs/engineering/reader-ddd-lexicon.md`
