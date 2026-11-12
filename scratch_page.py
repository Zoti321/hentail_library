import io

p = 'lib/features/named_metadata/presentation/views/metadata/metadata_page.dart'
s = io.open(p, encoding='utf-8').read()

start = s.index('  Widget _buildPage({')
end = s.index('  void _handleTabSelected(int index) {')
body = s[start:end]
s = s[:start] + s[end:]

# isolate the widget tree returned by the method
ret = body.index('    return Stack(')
body_tree = body[ret + len('    return '):].rstrip()
assert body_tree.endswith('}')
body_tree = body_tree[:-1].rstrip()  # drop method-closing brace

for old, new in [
    ('ref.watch(', 'host.ref.watch('),
    ('ref.read(', 'host.ref.read('),
    ('_scrollController', 'host._scrollController'),
    ('_showInlineCreateField', 'host._showInlineCreateField'),
    ('_facetTransitionReverse', 'host._facetTransitionReverse'),
    ('_onCreatePressed', 'host._onCreatePressed'),
    ('_commitDraftEntity', 'host._commitDraftEntity'),
    ('_dismissDraftEntity', 'host._dismissDraftEntity'),
    ('_mergeSelectedNames', 'host._mergeSelectedNames'),
    ('_handleTabSelected', 'host._handleTabSelected'),
]:
    body_tree = body_tree.replace(old, new)

cls = """class _MetadataPageView extends ConsumerWidget {
  const _MetadataPageView({
    required this.host,
    required this.layout,
    required this.selectedIndex,
  });

  final _MetadataManagementPageState host;
  final PageLayoutSpec layout;
  final int selectedIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ManagedNamedFacetKind kind = metadataTabKind(selectedIndex);
    final (
      bool hasSearchQuery,
      int itemCount,
      int totalCount,
      String? mergeTarget,
      Set<String> mergeSources,
      int mergeSelectionCount,
    ) = host.ref.watch(
      namedFacetManagementViewModelProvider(kind).select(
        (NamedFacetManagementState s) => (
          s.hasSearchQuery,
          s.items.length,
          s.totalCount,
          s.mergeTarget,
          s.mergeSources,
          s.mergeSelectionCount,
        ),
      ),
    );
    final NamedFacetManagementViewModel viewModel = host.ref.read(
      namedFacetManagementViewModelProvider(kind).notifier,
    );
    final double horizontal = layout.horizontalInset;
    final bool mergeMode = mergeTarget != null;
    final bool useMobileCreateDialog =
        managementCreateInteractionOf(context) ==
        ManagementCreateInteraction.mobileDialog;
    final bool showInlineCreate =
        !useMobileCreateDialog && host._showInlineCreateField;

    return """ + body_tree.strip() + """;
  }
}

"""

anchor = '/// 实体类型 tab 索引 → 命名元数据维度。'
s = s.replace(anchor, cls + anchor, 1)

# update the call site
s = s.replace(
    """          child: _buildPage(
            context: context,
            layout: PageLayoutSpec.of(context),
            selectedIndex: selectedIndex,
          ),""",
    """          child: _MetadataPageView(
            host: this,
            layout: PageLayoutSpec.of(context),
            selectedIndex: selectedIndex,
          ),""",
)

# extract onInvoke / onChanged closures
s = s.replace(
    """            onInvoke: (_MetadataAddIntent intent) {
              if (_isTextInputFocused()) {
                return null;
              }
              _onCreatePressed(context, metadataTabKind(selectedIndex));
              return null;
            },""",
    """            onInvoke: (_MetadataAddIntent intent) =>
                _handleAddIntent(context, selectedIndex),""",
)
s = s.replace(
    """                onChanged: (String value) {
                  if (value.trim().isEmpty) {
                    unawaited(viewModel.setQuery(''));
                    return;
                  }
                  viewModel.setQueryDebounced(value);
                },""",
    """                onChanged: host._handleSearchChanged,""",
)

s = s.replace(
    """  void _handleTabSelected(int index) {""",
    """  Object? _handleAddIntent(BuildContext context, int selectedIndex) {
    if (_isTextInputFocused()) {
      return null;
    }
    _onCreatePressed(context, metadataTabKind(selectedIndex));
    return null;
  }

  void _handleSearchChanged(String value) {
    final ManagedNamedFacetKind kind = metadataTabKind(_selectedTabIndex ?? 1);
    final NamedFacetManagementViewModel viewModel = ref.read(
      namedFacetManagementViewModelProvider(kind).notifier,
    );
    if (value.trim().isEmpty) {
      unawaited(viewModel.setQuery(''));
      return;
    }
    viewModel.setQueryDebounced(value);
  }

  void _handleTabSelected(int index) {""",
    1,
)

io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('ok')
