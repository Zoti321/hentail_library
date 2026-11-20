# Domain naming

Authority: [GLOSSARY](../../GLOSSARY.md) nouns and the types under `features/*/domain/` and `shared/domain/`. This guide only fixes naming templates and Reader disambiguation (ADR-0038/0050/0061). Layout and dependency direction live in architecture/gate tests — see [cross-feature-collaboration.md](cross-feature-collaboration.md).

## Templates

Keep the file name aligned with its main type.

- Entity/aggregate projection: the domain noun, `{aggregate}.dart`.
- Value object: `{Name}`, under `value_objects/`; validate invariants at construction.
- Repository interface: `{Name}Repository`, `{name}_repository.dart`.
- Domain service: `{Name}DomainService`, `{name}_domain_service.dart`.
- Specification: `{Name}Specification`, `{name}_specification.dart`; pure static rules may use an abstract final class.
- Strategy: an enum plus pure functions, `{name}_strategy.dart`.
- Domain exception: `{Context}Exception`, `{context}_exceptions.dart`, based on `shared/domain/exceptions/domain_exception.dart`.
- Domain event family: sealed `{Context}Event`, `{context}_events.dart`, under `shared/domain/events/` (ADR-0039).

New types belong to the feature owner. Comic/Series projection entities do not move Rust's transaction boundary into Dart — see [rust-write-semantics.md](rust-write-semantics.md). FRB mapping stays in owner infrastructure. Application errors (`shared/application/errors/`) are distinct from domain invariant failures; adapters map technical failures without discarding cause/stack. Concrete use-case orchestration belongs to `application/`, not a domain service.

## Reader

The product module is `features/reader/`. A **Read session** is its domain lifecycle, not a module name.

| Prefix | Use for |
|--------|---------|
| `ReadSession*` | Session entities, values, capabilities, subjects, rules and application services |
| `Reader*` / `NativeReader*` | Comic resource payloads, native contracts and UI |

Rules:

- Do not use `comicId` for an Image set session key in new APIs (`sessionKey` is opaque cache identity). Enforced in part by `app/test/architecture/reader_no_image_set_string_protocol_test.dart`.
- `ReadSessionCapabilities` is the only catalog-kind branch for shared vs Comic-only features (ADR-0061). Views read capabilities; they do not branch on catalog kind or call application services directly.
- Route-only input (`OpenReaderArgs` for Comic) is not a session entity. Image set uses `ReadSessionSource` / route context.
- Cross-feature Comic launch: AppNavigator + Reader public `openReader`. Image set: `ReaderPage.forSource` on a stacked route (ADR-0050).
- `ManageReadSessionUseCase.prepareImageSetSwitch` closes the current Image set session and returns a new `ImageSetReadSessionSource` (no `OpenReaderArgs`, no progress writes).
- Do not disguise Image set as `ReaderComicRef`. Do not add another main Controller/Facade/Coordinator chain beside the existing ViewModel/notifiers.
