# Reader naming

The product module is `features/reader/` (ADR-0038). A **Read session** is its domain lifecycle, not a module name. Use [GLOSSARY](../../GLOSSARY.md) for session, progress and image-fidelity semantics.

## Types and layers

- `ReadSession`: entity in `domain/read_session.dart`; that file does not hold route arguments.
- `ReadSessionPageIndex`, `ReadSessionException`: session values and rule failures in domain.
- `OpenedReadSession`, `ReaderPagePayload`: domain read models/payloads.
- `NativeReaderPort`, `ComicPageSourcePort`, `ClipboardImagePort`: external capability contracts in domain.
- `SpreadNavigation`, `AutoPlayBoundaryPolicy`, `PagePrefetchWindow`: pure domain policies.
- `OpenReaderArgs`: application input, separate from the entity.
- `OpenReadSessionService`, `ReadSessionApplicationService`, `CopyPageImageService`, `PrepareReaderContextUseCase`: application orchestration.
- `ReadSessionPageLoadException`: application error mapping, distinct from a domain invariant failure.
- `ReaderViewModel` / `ReaderUiState`: page commands and presentation state.
- `ReaderChromeNotifier`, `ReaderPrefetchNotifier`, `ReaderTapZone`: presentation concerns, not extra session aggregates.

Cross-feature launch uses AppNavigator and the Reader public `openReader` helper. The former ReaderLaunchPort forwarding chain is retired (ADR-0050).

## Naming rules

Use `ReadSession*` for session entities, values, rules and application services; use `Reader*` / `NativeReader*` for resource payloads, native contracts and UI. Route-only input does not become a session entity. New page command APIs use the ViewModel; views do not call application services directly or add another main Controller/Facade/Coordinator chain. File names follow [ddd-domain-naming.md](ddd-domain-naming.md).
