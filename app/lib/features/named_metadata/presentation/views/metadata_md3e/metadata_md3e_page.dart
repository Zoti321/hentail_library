import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/named_facet_management_controller.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata_md3e/metadata_md3e_actions.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata_md3e/metadata_md3e_dialogs.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata_md3e/metadata_md3e_facet_list.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata_md3e/metadata_md3e_header.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata_md3e/named_facet_fill_viewport.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata_md3e/patterns/md3e_management_catalog_toolbar.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata_md3e/patterns/md3e_management_create_entity_dialog.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_library_browse_page_metrics.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:hentai_library/shared/domain/repositories/named_facet_management_repository.dart';
import 'package:hentai_library/shared/ui/layout/app_shell_navigation.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/shared/ui/widgets/navigation/library_scroll_to_top_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kMergeConfirmSkipKey = 'metadata_merge_confirm_skip';

/// 元数据管理页（MD3E 生产版）：作者 / 标签 / 原作 / 角色四类命名元数据。
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
  final ScrollController _scrollController = ScrollController();
  int? _selectedTabIndex;
  String? _mergeTarget;
  final Set<String> _mergeSources = <String>{};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScrollLoadMore);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScrollLoadMore);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? tabParam = GoRouterState.of(context)
        .uri
        .queryParameters['tab'];
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
              _invokeAdd(context, metadataTabKind(selectedIndex));
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Md3eThemeScope(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final Md3eWindowSizeClass sizeClass =
                    Md3eWindowSizeClass.fromWidth(constraints.maxWidth);
                return _buildPage(
                  context: context,
                  sizeClass: sizeClass,
                  selectedIndex: selectedIndex,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage({
    required BuildContext context,
    required Md3eWindowSizeClass sizeClass,
    required int selectedIndex,
  }) {
    final ManagedNamedFacetKind kind = metadataTabKind(selectedIndex);
    final NamedFacetManagementState state = ref.watch(
      namedFacetManagementControllerProvider(kind),
    );
    final int count = state.hasSearchQuery
        ? state.items.length
        : state.totalCount;
    final bool compact = sizeClass.isCompact;
    final double horizontal =
        Md3eLibraryBrowsePageMetrics.contentHorizontalPadding(sizeClass);
    final bool mergeMode = _mergeTarget != null;

    final Widget body = Stack(
      children: <Widget>[
        CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverPersistentHeader(
              pinned: true,
              delegate: _MetadataHeaderDelegate(
                extent: kMetadataMd3eHeaderExtent,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontal),
                  child: MetadataMd3eHeader(
                    compact: compact,
                    totalCount: count,
                    showDeleteAllTags: kind == ManagedNamedFacetKind.tag,
                    addTooltip: context.l10n.metadataAddEntityTooltip(
                      selectedIndex,
                    ),
                    onOpenNavigation: appShellPageNavigationOpener(context),
                    onAdd: () => _invokeAdd(context, kind),
                    onDeleteAllTags: kind == ManagedNamedFacetKind.tag
                        ? () => unawaited(deleteAllTags(context, ref))
                        : null,
                    mergeSelectionCount: mergeMode
                        ? 1 + _mergeSources.length
                        : 0,
                    onExitMergeSelection: mergeMode
                        ? _exitMergeSelection
                        : null,
                    onMergeSelection: mergeMode
                        ? () => unawaited(_mergeSelectedNames())
                        : null,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (!compact) ...<Widget>[
                      Md3eManagementCatalogToolbar(
                        facet: kind,
                        facetCount: count,
                        onFacetChanged: (ManagedNamedFacetKind value) =>
                            _handleTabSelected(
                              kManagedNamedFacetTabOrder.indexOf(value),
                            ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    MetadataMd3eSearchField(
                      key: ValueKey<int>(selectedIndex),
                      initialQuery: state.query,
                      onChanged: (String value) {
                        ref
                            .read(
                              namedFacetManagementControllerProvider(kind)
                                  .notifier,
                            )
                            .setQuery(value);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (_visitedTabIndexes.contains(selectedIndex))
              MetadataMd3eFacetSliver(
                kind: kind,
                horizontalPadding: horizontal,
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
          kind: kind,
        ),
        LibraryScrollToTopButton(
          scrollController: _scrollController,
          isDrawerOpen: false,
        ),
      ],
    );

    if (!compact) {
      return body;
    }

    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: _handleTabSelected,
        indicatorColor: scheme.secondaryContainer,
        destinations: <NavigationDestination>[
          for (final ManagedNamedFacetKind facet in kManagedNamedFacetTabOrder)
            NavigationDestination(
              icon: Icon(_iconForFacet(facet)),
              label: context.l10n.metadataTabLabel(facet),
            ),
        ],
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

  void _scrollToContentTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
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
    final ManagedNamedFacetKind kind = metadataTabKind(_selectedTabIndex ?? 1);
    final prefs = await SharedPreferences.getInstance();
    final bool skip = prefs.getBool(_kMergeConfirmSkipKey) ?? false;
    if (!skip && mounted) {
      final bool confirmed = await showMetadataMd3eMergeConfirmDialog(
        context: context,
        target: target,
        sourceCount: sources.length,
        onSkipChanged: (bool value) =>
            prefs.setBool(_kMergeConfirmSkipKey, value),
      );
      if (!confirmed || !mounted) return;
    }
    try {
      await ref
          .read(namedFacetManagementControllerProvider(kind).notifier)
          .merge(targetName: target, sourceNames: sources);
      if (mounted) {
        _exitMergeSelection();
        showSuccessToast(context, '合并完成');
      }
    } catch (error) {
      if (mounted) showErrorToast(context, error);
    }
  }

  void _invokeAdd(BuildContext context, ManagedNamedFacetKind kind) {
    unawaited(
      showMd3eManagementCreateEntityDialog(
        context: context,
        facet: kind,
        onCreate: (String name) {
          unawaited(
            ref
                .read(namedFacetManagementControllerProvider(kind).notifier)
                .add(name),
          );
        },
      ),
    );
  }

  void _handleScrollLoadMore() {
    if (!_scrollController.hasClients) {
      return;
    }
    final ScrollPosition position = _scrollController.position;
    final ManagedNamedFacetKind kind = metadataTabKind(_selectedTabIndex ?? 1);
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

class _MetadataHeaderDelegate extends SliverPersistentHeaderDelegate {
  _MetadataHeaderDelegate({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: shrinkOffset > 0 || overlapsContent ? 2 : 0,
      shadowColor: scheme.shadow,
      surfaceTintColor: Colors.transparent,
      child: Align(alignment: Alignment.topCenter, child: child),
    );
  }

  @override
  bool shouldRebuild(covariant _MetadataHeaderDelegate oldDelegate) {
    return oldDelegate.extent != extent || oldDelegate.child != child;
  }
}

/// 实体类型 tab 索引 → 命名元数据维度。
ManagedNamedFacetKind metadataTabKind(int index) {
  if (index < 0 || index >= kManagedNamedFacetTabOrder.length) {
    return kManagedNamedFacetTabOrder.first;
  }
  return kManagedNamedFacetTabOrder[index];
}

IconData _iconForFacet(ManagedNamedFacetKind kind) => switch (kind) {
  ManagedNamedFacetKind.author => LucideIcons.penLine,
  ManagedNamedFacetKind.tag => LucideIcons.tags,
  ManagedNamedFacetKind.parody => LucideIcons.clapperboard,
  ManagedNamedFacetKind.character => LucideIcons.userRound,
};

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
