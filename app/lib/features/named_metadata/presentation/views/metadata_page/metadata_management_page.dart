import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/repositories/named_facet_management_repository.dart';
import 'package:hentai_library/ui/core/layout/page_content_width_layout.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/shared/ui/widgets/navigation/library_scroll_to_top_button.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata_page/widgets/metadata_content_search.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata_page/widgets/metadata_layout_constants.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata_page/widgets/metadata_page_header.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata_page/widgets/named_facet_fill_viewport.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata_page/widgets/named_facet_management_panel.dart';
import 'package:hentai_library/ui/features/shell/views/responsive_app_shell.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/tag_confirm_delete_dialog.dart';

class MetadataManagementPage extends ConsumerStatefulWidget {
  const MetadataManagementPage({super.key});

  @override
  ConsumerState<MetadataManagementPage> createState() =>
      _MetadataManagementPageState();
}

class _MetadataAddIntent extends Intent {
  const _MetadataAddIntent();
}

class _MetadataManagementPageState
    extends ConsumerState<MetadataManagementPage> {
  final Set<int> _visitedTabIndexes = <int>{};
  final GlobalKey _headerMeasureKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  int? _selectedTabIndex;
  double? _headerExtent;
  String? _mergeTarget;
  final Set<String> _mergeSources = <String>{};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScrollLoadMore);
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScrollLoadMore);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
  }

  void _measureHeaderExtent(Duration _) {
    final RenderBox? box =
        _headerMeasureKey.currentContext?.findRenderObject() as RenderBox?;
    if (!mounted || box == null) {
      return;
    }
    final double height = box.size.height;
    if (_headerExtent != height) {
      setState(() => _headerExtent = height);
    }
  }

  void _scrollToContentTop() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final String? tabParam = GoRouterState.of(
      context,
    ).uri.queryParameters['tab'];
    final int selectedIndex = _selectedTabIndex ?? _tabIndexFromQuery(tabParam);
    _selectedTabIndex ??= selectedIndex;
    _visitedTabIndexes.add(selectedIndex);

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyN, control: true):
            _MetadataAddIntent(),
        SingleActivator(LogicalKeyboardKey.keyN, meta: true):
            _MetadataAddIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _MetadataAddIntent: CallbackAction<_MetadataAddIntent>(
            onInvoke: (_MetadataAddIntent intent) {
              if (_isTextInputFocused()) {
                return null;
              }
              _invokeAddForTab(context, selectedIndex);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double viewportWidth = constraints.maxWidth;
              final MetadataLayoutTier layoutTier = metadataLayoutTierForWidth(
                viewportWidth,
              );
              final double horizontalPadding = metadataContentHorizontalPadding(
                layoutTier,
              );
              final double innerMaxWidth = metadataInnerContentMaxWidth(
                layoutTier,
                viewportWidth,
              );

              return _buildPage(
                layoutTier: layoutTier,
                horizontalPadding: horizontalPadding,
                viewportWidth: viewportWidth,
                innerMaxWidth: innerMaxWidth,
                selectedIndex: selectedIndex,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPage({
    required MetadataLayoutTier layoutTier,
    required double horizontalPadding,
    required double viewportWidth,
    required double innerMaxWidth,
    required int selectedIndex,
  }) {
    final Widget headerSection = MetadataPageHeaderSection(
      layoutTier: layoutTier,
      horizontalPadding: horizontalPadding,
      contentMaxWidth: innerMaxWidth,
      selectedTabIndex: selectedIndex,
      onTabSelected: _handleTabSelected,
      onAdd: () => _invokeAddForTab(context, selectedIndex),
      onDeleteAllTags: selectedIndex == 1
          ? () => _deleteAllTags(context)
          : null,
      onOpenNavigation: appShellPageNavigationOpener(context),
      mergeSelectionCount: _mergeTarget == null ? 0 : 1 + _mergeSources.length,
      onExitMergeSelection: _mergeTarget == null ? null : _exitMergeSelection,
      onMergeSelection: _mergeTarget == null ? null : _mergeSelectedNames,
    );
    final Widget header = KeyedSubtree(
      key: _headerMeasureKey,
      child: headerSection,
    );

    final Widget body = Stack(
      children: <Widget>[
        CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            if (_headerExtent == null)
              SliverToBoxAdapter(child: header)
            else
              SliverPersistentHeader(
                pinned: true,
                delegate: MetadataPinnedHeaderDelegate(
                  extent: _headerExtent!,
                  child: header,
                ),
              ),
            SliverToBoxAdapter(
              child: PageContentWidthAlign(
                horizontalPadding: horizontalPadding,
                maxWidth: innerMaxWidth,
                child: MetadataContentSearch(
                  layoutTier: layoutTier,
                  selectedTabIndex: selectedIndex,
                  contentMaxWidth: innerMaxWidth,
                ),
              ),
            ),
            if (_visitedTabIndexes.contains(selectedIndex))
              NamedFacetManagementSliverGroup(
                kind: metadataTabKind(selectedIndex),
                layoutTier: layoutTier,
                viewportWidth: viewportWidth,
                horizontalPadding: horizontalPadding,
                contentMaxWidth: innerMaxWidth,
                mergeTarget: _mergeTarget,
                mergeSources: _mergeSources,
                onMergeTargetSelected: _enterMergeSelection,
                onMergeSourceSelected: _selectMergeSource,
                onMergeSelectionExited: _exitMergeSelection,
              ),
          ],
        ),
        NamedFacetFillViewportBinder(
          scrollController: _scrollController,
          kind: metadataTabKind(selectedIndex),
        ),
        LibraryScrollToTopButton(
          scrollController: _scrollController,
          isDrawerOpen: false,
        ),
      ],
    );

    if (!metadataUsesContentSwitcherBottomBar(layoutTier)) {
      return body;
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: MetadataEntityBottomBar(
        selectedTabIndex: selectedIndex,
        onTabSelected: _handleTabSelected,
      ),
    );
  }

  void _handleTabSelected(int index) {
    if (_selectedTabIndex == index) {
      return;
    }
    _exitMergeSelection();
    setState(() {
      _selectedTabIndex = index;
    });
    context.go('/metadata?tab=${_tabQueryForIndex(index)}');
    _scrollToContentTop();
  }

  void _enterMergeSelection(String target) {
    if (metadataTabKind(_selectedTabIndex ?? 1) ==
        ManagedNamedFacetKind.author) {
      return;
    }
    setState(() {
      _mergeTarget = target;
      _mergeSources.clear();
    });
  }

  void _selectMergeSource(String source) {
    if (_mergeTarget == null || source == _mergeTarget) return;
    setState(() {
      if (!_mergeSources.add(source)) _mergeSources.remove(source);
    });
  }

  void _exitMergeSelection() {
    if (_mergeTarget == null && _mergeSources.isEmpty) return;
    setState(() {
      _mergeTarget = null;
      _mergeSources.clear();
    });
  }

  Future<void> _mergeSelectedNames() async {
    final String? target = _mergeTarget;
    final List<String> sources = _mergeSources.toList(growable: false);
    if (target == null || sources.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final bool skip = prefs.getBool('metadata_merge_confirm_skip') ?? false;
    if (!skip && mounted) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => _MergeConfirmDialog(
          target: target,
          sources: sources,
          onSkipChanged: (value) =>
              prefs.setBool('metadata_merge_confirm_skip', value),
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    try {
      await ref
          .read(
            namedFacetManagementControllerProvider(
              metadataTabKind(_selectedTabIndex ?? 1),
            ).notifier,
          )
          .merge(targetName: target, sourceNames: sources);
      if (mounted) {
        _exitMergeSelection();
        showSuccessToast(context, '合并完成');
      }
    } catch (error) {
      if (mounted) showErrorToast(context, error);
    }
  }

  Future<void> _invokeAddForTab(BuildContext context, int tabIndex) async {
    await openNamedFacetCreateDialog(context, ref, metadataTabKind(tabIndex));
  }

  Future<void> _deleteAllTags(BuildContext context) async {
    final List<Tag> tags = await ref.read(allTagsProvider.future);
    if (!context.mounted || tags.isEmpty) {
      return;
    }

    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) =>
              TagConfirmDeleteDialog(count: tags.length),
        ) ??
        false;
    if (!context.mounted || !confirmed) {
      return;
    }

    await ref.read(tagActionsProvider).deleteAllTags();
    await ref
        .read(
          namedFacetManagementControllerProvider(metadataTabKind(1)).notifier,
        )
        .refresh();
    if (!context.mounted) {
      return;
    }
    showSuccessToast(context, context.l10n.metadataTagsDeletedAllToast);
  }

  void _handleScrollLoadMore() {
    if (!_scrollController.hasClients) {
      return;
    }
    final ScrollPosition position = _scrollController.position;
    final int selectedIndex = _selectedTabIndex ?? 1;
    final ManagedNamedFacetKind kind = metadataTabKind(selectedIndex);
    final NamedFacetManagementState state = ref.read(
      namedFacetManagementControllerProvider(kind),
    );
    if (!namedFacetShouldAutoLoadMore(
      hasMore: state.hasMore,
      hasSearchQuery: state.hasSearchQuery,
      isLoading: state.isLoading,
      isLoadingMore: state.isLoadingMore,
      hasError: false,
      maxScrollExtent: position.maxScrollExtent,
      pixels: position.pixels,
    )) {
      return;
    }
    ref.read(namedFacetManagementControllerProvider(kind).notifier).loadMore();
  }
}

bool _isTextInputFocused() {
  final FocusNode? node = FocusManager.instance.primaryFocus;
  final BuildContext? ctx = node?.context;
  if (ctx == null) {
    return false;
  }
  return ctx.widget is EditableText;
}

int _tabIndexFromQuery(String? tab) {
  switch (tab) {
    case 'authors':
      return 0;
    case 'tags':
      return 1;
    case 'parodies':
      return 2;
    case 'characters':
      return 3;
    default:
      return 1;
  }
}

String _tabQueryForIndex(int index) {
  return switch (index) {
    0 => 'authors',
    1 => 'tags',
    2 => 'parodies',
    3 => 'characters',
    _ => 'tags',
  };
}

class _MergeConfirmDialog extends StatefulWidget {
  const _MergeConfirmDialog({
    required this.target,
    required this.sources,
    required this.onSkipChanged,
  });

  final String target;
  final List<String> sources;
  final ValueChanged<bool> onSkipChanged;

  @override
  State<_MergeConfirmDialog> createState() => _MergeConfirmDialogState();
}

class _MergeConfirmDialogState extends State<_MergeConfirmDialog> {
  bool skip = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return HentaiDialog(
      title: '确认合并',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '将 ${widget.sources.length} 个 tag 合并到「${widget.target}」？源 tag 的 Comic 附着会转移到目标，源 tag 将被删除。',
            style: TextStyle(color: cs.hentai.textSecondary),
          ),
          CheckboxListTile(
            value: skip,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('以后不再提示'),
            onChanged: (value) {
              setState(() => skip = value ?? false);
              widget.onSkipChanged(skip);
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.l10n.metadataMerge),
        ),
      ],
    );
  }
}
