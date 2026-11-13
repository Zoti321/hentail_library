# Browse, Comic and Series boundaries

ADR-0036 separates three product modules. `library_browse` owns the current-Library shell, search, author details, query state and cross-tab UI assembly. `comic` owns Comic rules/details/metadata UX; `series` owns Series rules/details/membership/order.

## Shell collaboration

Search/filter/sort/group state and pagination assembly stay in browse. ComicCatalogQueryAssembly and SeriesCatalogQueryAssembly combine intent with rules exposed by the corresponding owner public API. List rows use read-only records (ADR-0040); Series does not expose its entity (ADR-0042). Author/Tag entities belong to comic_metadata (ADR-0048).

Browse observes owner public provider tokens in one direction. Product modules do not read browse state back. Shared UI composition uses `shared/ui/slots/` and required shared providers, with owner implementations bound in `composition/`.

## Dependency direction

`library_browse` may consume comic/series public APIs; series may consume permitted comic public capabilities. Comic cannot depend on browse, series or reader; series cannot depend on browse; Reader cannot depend on series or comic. Reader cover editing uses shared commands bound to the owners by composition. The complete forbidden-edge set and baselines are maintained in `app/test/architecture/module_boundary_test.dart` and `app/test/gate/`, not duplicated here.

Use shared membership/reading-context contracts when an owner is unreachable. Do not revive presentation bridges or export chains that hide a forbidden edge. Boundary checks inspect imports and exports; ordinary public facades remain export-only under ADR-0051.

## Consistency

`library_browse/domain/browse` owns Comic and Series browse preference values and the typed preferences repository contract. Notifiers retain optimistic UI updates, transient language/parody/character filters and query projections; they do not read storage keys or invoke SharedPreferences. The owner infrastructure adapter handles independent field writes, default-key removal, legacy age/grouping/author-ID migrations and page-size normalization. Composition binds the adapter and its Author repository dependency. Keep reset failures visible and preserve session state until persistent reset succeeds; do not replace field writes with whole-preference saves that overwrite unrelated dimensions.

Shared page-size values and normalization belong to `shared/domain/models/value_objects`, since browse and Series detail both consume them. Page-size controls and preference-to-widget adapters remain in UI.

Series detail persists its own page size through injected query/command functions. Its storage key and SharedPreferences operations remain with Series infrastructure; the Notifier retains optimistic updates and propagates write failures.

Rust owns catalog predicates, membership rebuilding, ordering locks and aggregate writes. Browse assembles filter intent rather than duplicating SQL rules in memory. Comic metadata, Series ordering, trash and library-level bulk/sync retain their respective owners. See [shared-domain-ownership.md](shared-domain-ownership.md) and [cross-feature-collaboration.md](cross-feature-collaboration.md).
