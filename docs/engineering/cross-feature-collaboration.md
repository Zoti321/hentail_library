# Cross-feature collaboration

Follow ADR-0034/0039/0045/0050/0051. First check whether the consumer may reach the producer: cross-feature dependencies use owner public APIs, respect forbidden edges and keep the public graph acyclic. Shared/core cannot depend on features. `composition/` binds implementations and bridges dependencies.

## Public surfaces

`features/<owner>/public.dart` aggregates only the available capability surfaces:

- `public/contracts.dart`: pure Dart types, repository/IO contracts, Command/Query signatures and rules.
- `public/providers.dart`: observable state and Command/Query tokens.
- `public/widgets.dart`: pages, components and presentation helpers.

Public files contain exports only. Use an existing narrow export when a broad barrel would pull UI into inner code. Canonical presentation exports select symbols explicitly; provider surfaces export provider tokens. Factories and overrides stay in composition. `public/infrastructure/` is a dedicated adapter-to-adapter surface excluded from ordinary barrels.

## Capability shape

- **Command**: a typed function. `ref.read(commandProvider)(...)` executes at call time; constructing or rebuilding a provider performs no business write. Read the current Notifier inside the callback or bind a stable pure Dart use case.
- **Query**: a function for a one-time read. Preserve fresh reads and editing/session snapshots; do not replace them with an indefinitely cached FutureProvider.
- **Continuous state**: owner StreamProvider/state Provider, consumed with `watch/select`. Preserve initial loading, data, errors, subsequent changes and cancellation.
- **Committed fact**: a DomainEvent, published from application/infrastructure and projected through DomainEventRevisions. Use `listen` for reactions to state, not as a second event bus.
- **External IO**: retain meaningful Repository, NativeReader, ComicPageSource, Clipboard and sync/refresh contracts. Add a small Gateway only when it isolates actual IO.

Shared pure Dart collaboration signatures live in `shared/application/contracts/`; signatures requiring BuildContext live in `shared/ui/contracts/`. Tokens live in `shared/presentation/providers/`. A shared placement requires an unreachable owner, a public cycle, or a shared consumer; it cannot bypass a forbidden dependency.

## Product seams

Navigation uses AppNavigator and AppRoutes; go_router belongs to the routing host. `openReader` preserves its Future result. Shared ComicReadQuery supplies Reader metadata across the forbidden reader-to-comic edge. Series membership, reading context and ordering use shared contracts bound to series. Reading progress/activity capabilities stay with reading_history/reading_stats; shared progress consumers observe the existing shared stream.

Library commands preserve busy/backup guards, credential/root/settings ordering and core write exclusion. Metadata backup prepares a preview and manifest from the same payload, then commits after confirmation. Auto-backup execution/concurrency/success records belong to its use case; subscriptions, debounce and lifecycle cancellation remain in integration code, while file compression/retention belongs to the Gateway. Preserve partial commits: a later failure must not silently retry or compensate an earlier successful write.

Domain facts and event interfaces have one source in `shared/domain/events/`. The implementation is `infrastructure/events/StreamDomainEventBus`; providers are adapters, not event publishers in presentation.

## Verification

Exercise public ProviderContainer behavior or construct pure Dart use cases with explicit dependencies. Cover lazy execution, one call per invocation, write order/partial failure, committed events and stream initial values/updates/errors/disposal. Run module/public/dependency and override-coverage checks plus affected composition tests. See [gate.md](gate.md).
