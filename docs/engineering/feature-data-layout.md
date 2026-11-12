# Dart layout and external adapters

Follow ADR-0051/0052. `app/lib/` is organized by owner, with these dependency boundaries:

- `features/<owner>/domain/`: entities, value objects, rules and repository/IO contracts.
- `features/<owner>/application/`: concrete use cases depending on domain contracts.
- `features/<owner>/infrastructure/`: FRB mapping, repository implementations and platform/file/network adapters.
- `features/<owner>/presentation/`: views, view models and provider bindings to abstract contracts.
- `features/<owner>/public/`: export-only contracts, providers and widgets; see [cross-feature collaboration](cross-feature-collaboration.md).
- `composition/`: concrete factories, overrides, cross-module bridges, startup and platform binding. Product modules do not import it.

Domain and application must remain pure Dart through the entire dependency graph, including exports, parts, conditional imports and third-party runtime dependencies. Domain does not depend on application. Presentation consumes injected contracts rather than constructing infrastructure. Required providers fail explicitly until composition supplies them. Do not reintroduce feature `data/` or `di/` layers.

## External implementation placement

Keep business adapters with their feature owner. For new grouped adapters, use `infrastructure/repositories/` (`*_repository_impl.dart`), `mappers/` (`*_frb_mapper.dart`), `adapters/` (`*_adapter.dart`) or `services/` (`*_service.dart`) as needed. Existing flat owner layouts remain valid; avoid a directory-only migration.

Top-level `infrastructure/` contains feature-independent technical implementations: FRB guards, the event bus, logging, file browsing and native window operations. Update opening, diagnostic export and backup IO stay with their business owner. FRB DTOs are translated at the adapter boundary; inner code uses domain types.

## Core and shared

`core/` contains product-independent pure Dart utilities. It cannot depend on Flutter, Riverpod, `dart:io`, FRB, plugins or other application directories.

Use shared layers only for justified product collaboration:

- `shared/domain/`: Shared Kernel values, rules and domain facts.
- `shared/application/`: collaboration contracts, routes, application errors and logging entry points.
- `shared/presentation/providers/`: required collaboration tokens and event projections.
- `shared/ui/`: product navigation, selection, domain-to-UI and image adapters.

Ownership and reachability rules are in [shared-domain-ownership.md](shared-domain-ownership.md). Design-system independence and application ARB placement are defined by [design-system.md](design-system.md), following ADR-0053's revision of ADR-0052.

## Verification

Run affected architecture tests, especially `test/architecture/clean_architecture_dependency_test.dart`, `public_interface_test.dart` and `test/project_layout_test.dart` from `app/`. The recursive scanner must fail on unresolved files/packages; preserve import baselines and required-provider coverage when moving code. See [gate.md](gate.md).
