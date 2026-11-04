/// Copy strings for [Md3eNamedFacetMultiSelectField] empty/error states.
class Md3eNamedFacetMultiSelectCopy {
  const Md3eNamedFacetMultiSelectCopy({
    required this.listLoadFailed,
    required this.emptyCatalog,
    required this.emptyRemaining,
    required this.retryLabel,
  });

  final String listLoadFailed;
  final String emptyCatalog;
  final String emptyRemaining;

  /// 浮层 error 态重试按钮（须在字段树内 resolve，overlay 内无 [AppLocalizations]）。
  final String retryLabel;
}
