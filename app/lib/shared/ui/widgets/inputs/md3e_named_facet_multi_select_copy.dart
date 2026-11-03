/// Copy strings for [Md3eNamedFacetMultiSelectField] empty/error states.
class Md3eNamedFacetMultiSelectCopy {
  const Md3eNamedFacetMultiSelectCopy({
    required this.listLoadFailed,
    required this.emptyCatalog,
    required this.emptyRemaining,
  });

  final String listLoadFailed;
  final String emptyCatalog;
  final String emptyRemaining;
}
