# Reader naming

The product module is `features/reader/` (ADR-0038). A **Read session** is its domain lifecycle, not a module name. Use [GLOSSARY](../../GLOSSARY.md) for session, progress and image-fidelity semantics.

## Types and layers

- `ReadSession`: entity in `domain/read_session.dart` for Comic sessions that persist progress; that file does not hold route arguments.
- `ReadSessionSource`: sealed open source (Comic or Image set); `sessionKey` is opaque cache identity, not a Comic id for Image set.
- `ReadSessionCapabilities`: domain flags derived from source/incognito; the only catalog-kind branch for shared vs Comic-only features (ADR-0061).
- `ReadSessionSubject`: session display header (`sessionKey`, title, pageCount) for both sources.
- `ReaderComicRef`: Comic-only narrow model for native page IO; do not disguise Image set as this type.
- `ReadSessionPageIndex`, `ReadSessionException`: session values and rule failures in domain.
- `OpenedReadSession`, `ReaderPagePayload`: domain read models/payloads (`OpenedReadSession` holds subject, source, capabilities, pages, resume index).
- `NativeReaderPort`, `ComicPageSourcePort`, `ImageSetReadPort`, `ClipboardImagePort`: external capability contracts in domain.
- `SpreadNavigation`, `AutoPlayBoundaryPolicy`, `PagePrefetchWindow`: pure domain policies.
- `OpenReaderArgs`: Comic application input, separate from the entity; Image set uses `ReadSessionSource` / route context.
- `OpenReadSessionUseCase`, `ManageReadSessionUseCase`, `CopyPageImageUseCase`, `PrepareReaderContextUseCase`: application orchestration.
- `ReadSessionPageLoadException`: application error mapping, distinct from a domain invariant failure.
- `ReaderViewModel` / `ReaderUiState`: page commands and presentation state keyed by `sessionKey` + source.
- `ReaderChromeNotifier`, `ReaderPrefetchNotifier`, `ReaderTapZone`: presentation concerns, not extra session aggregates.

Cross-feature Comic launch uses AppNavigator and the Reader public `openReader` helper. Image set launch uses `ReaderPage.forSource` on a stacked route. The former ReaderLaunchPort forwarding chain is retired (ADR-0050).

## Naming rules

Use `ReadSession*` for session entities, values, capabilities, subjects, rules and application services; use `Reader*` / `NativeReader*` for Comic resource payloads, native contracts and UI. Do not use `comicId` for an Image set session key in new APIs. Route-only input does not become a session entity. Views read capabilities rather than branching on catalog kind; they do not call application services directly or add another main Controller/Facade/Coordinator chain. File names follow [ddd-domain-naming.md](ddd-domain-naming.md).
