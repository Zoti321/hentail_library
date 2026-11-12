# Browse, Comic and Series boundaries

ADR-0036 separates three product modules. `library_browse` owns the current-Library shell, search, author details, query state and cross-tab UI assembly. `comic` owns Comic rules/details/metadata UX; `series` owns Series rules/details/membership/order.

## Shell collaboration

Search/filter/sort/group state and pagination assembly stay in browse. ComicCatalogQueryAssembly and SeriesCatalogQueryAssembly combine intent with rules exposed by the corresponding owner public API. List rows use read-only records (ADR-0040); Series does not expose its entity (ADR-0042). Author/Tag entities belong to comic_metadata (ADR-0048).

Browse observes owner public provider tokens in one direction. Product modules do not read browse state back. Shared UI composition uses `shared/ui/slots/` and required shared providers, with owner implementations bound in `composition/`.

## Dependency direction

`library_browse` may consume comic/series public APIs; series may consume permitted comic public capabilities. Comic cannot depend on browse, series or reader; series cannot depend on browse; Reader cannot depend on series. Existing reader-to-comic exceptions may only shrink. The complete forbidden-edge set and baselines are maintained in `app/test/architecture/module_boundary_test.dart` and `app/test/gate/`, not duplicated here.

Use shared membership/reading-context contracts when an owner is unreachable. Do not revive presentation bridges or export chains that hide a forbidden edge. Boundary checks inspect imports and exports; ordinary public facades remain export-only under ADR-0051.

## Consistency

Rust owns catalog predicates, membership rebuilding, ordering locks and aggregate writes. Browse assembles filter intent rather than duplicating SQL rules in memory. Comic metadata, Series ordering, trash and library-level bulk/sync retain their respective owners. See [shared-domain-ownership.md](shared-domain-ownership.md) and [cross-feature-collaboration.md](cross-feature-collaboration.md).
