# Dart domain naming

Applies to `features/*/domain/` and `shared/domain/`. Use [GLOSSARY](../../GLOSSARY.md) nouns and keep the file name aligned with its main type.

- Entity/aggregate projection: the domain noun, `{aggregate}.dart`.
- Value object: `{Name}`, under `value_objects/`; validate invariants at construction.
- Repository interface: `{Name}Repository`, `{name}_repository.dart`.
- Domain service: `{Name}DomainService`, `{name}_domain_service.dart`.
- Specification: `{Name}Specification`, `{name}_specification.dart`; pure static rules may use an abstract final class.
- Strategy: an enum plus pure functions, `{name}_strategy.dart`.
- Domain exception: `{Context}Exception`, `{context}_exceptions.dart`, based on `shared/domain/exceptions/domain_exception.dart`.
- Domain event family: sealed `{Context}Event`, `{context}_events.dart`, declared under `shared/domain/events/` (ADR-0039).

New types belong to the feature owner. Comic/Series projection entities do not move Rust's transaction boundary into Dart. FRB mapping stays in owner infrastructure. Application errors (`shared/application/errors/`) are distinct from domain invariant failures; adapters map technical failures without discarding their cause/stack.

Concrete use-case orchestration belongs to `application/`, not a domain service. Reader-specific naming and page/routing distinctions are in [reader-ddd-lexicon.md](reader-ddd-lexicon.md). Layout and recursive dependency constraints are in [feature-data-layout.md](feature-data-layout.md).
