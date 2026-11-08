import 'dart:async';

import 'package:hentai_library/shared/ui/patterns/shared/page_header.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/named_facet_management_view_model.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata/metadata_dialogs.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata/metadata_facet_list.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata/metadata_header.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata/named_facet_fill_viewport.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata/patterns/management_catalog_toolbar.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata/patterns/management_create_entity_dialog.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata/patterns/management_create_interaction.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata/patterns/management_draft_entity_chip.dart';
import 'package:hentai_library/shared/ui/widgets/navigation/management_create_entity_fab.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/shared/ui/layout/app_shell_navigation.dart';
import 'package:hentai_library/shared/ui/motion/peer_content_transition.dart';
import 'package:hentai_library/shared/ui/patterns/shared/page_header_back_button.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';
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
  final ScrollController _scrollController = ScrollController();
  int? _selectedTabIndex;
  bool _facetTransitionReverse = false;
  bool _showInlineCreateField = false;

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
    final String? tabParam = GoRouterState.of(
      context,
    ).uri.queryParameters['tab'];
    final int queryIndex = _tabIndexFromQuery(tabParam);
    // 首页统计卡等深链改 query 时，同步本地 tab（保留切换方向）。
    if (_selectedTabIndex != queryIndex) {
      final int previousIndex = _selectedTabIndex ?? queryIndex;
      _facetTransitionReverse = queryIndex < previousIndex;
      _selectedTabIndex = queryIndex;
      _showInlineCreateField = false;
    }
    final int selectedIndex = _selectedTabIndex!;

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
              _onCreatePressed(context, metadataTabKind(selectedIndex));
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: _buildPage(
            context: context,
            layout: PageLayoutSpec.of(context),
            selectedIndex: selectedIndex,
          ),
        ),
      ),
    );
  }

  Widget _buildPage({
    required BuildContext context,
    required PageLayoutSpec layout,
    required int selectedIndex,
  }) {
    final ManagedNamedFacetKind kind = metadataTabKind(selectedIndex);
    final NamedFacetManagementState state = ref.watch(
      namedFacetManagementViewModelProvider(kind),
    );
    final NamedFacetManagementViewModel viewModel = ref.read(
      namedFacetManagementViewModelProvider(kind).notifier,
    );
    final int count = state.hasSearchQuery
        ? state.items.length
        : state.totalCount;
    final double horizontal = layout.horizontalInset;
    final bool mergeMode = state.isMergeMode;
    final bool useMobileCreateDialog =
        managementCreateInteractionOf(context) ==
        ManagementCreateInteraction.mobileDialog;
    final bool showInlineCreate =
        !useMobileCreateDialog && _showInlineCreateField;

    final Widget body = Stack(
      children: <Widget>[
        CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverPersistentHeader(
              pinned: true,
              delegate: PageHeaderDelegate(
                layout: layout,
                child: MetadataHeader(
                  onOpenNavigation: appShellPageNavigationOpener(context),
                  onBack: () => popOrGoHome(context),
                  mergeSelectionCount: state.mergeSelectionCount,
                  onExitMergeSelection: mergeMode ? viewModel.exitMerge : null,
                  onMergeSelection: mergeMode
                      ? () => unawaited(_mergeSelectedNames(kind))
                      : null,
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                layout.headerToBodyGap,
                horizontal,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    ManagementCatalogToolbar(
                      facet: kind,
                      facetCount: count,
                      onFacetChanged: (ManagedNamedFacetKind value) =>
                          _handleTabSelected(
                            kManagedNamedFacetTabOrder.indexOf(value),
                          ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 32),
              sliver: SliverToBoxAdapter(
                child: PeerContentTransition(
                  switchKey: kind,
                  reverse: _facetTransitionReverse,
                  child: MetadataFacetContent(
                    kind: kind,
                    onCreatePressed: () => _onCreatePressed(context, kind),
                    draftChip: showInlineCreate
                        ? ManagementDraftEntityChip(
                            onCommit: (String name) =>
                                _commitDraftEntity(kind, name),
                            onDismiss: _dismissDraftEntity,
                          )
                        : null,
                    mergeTarget: state.mergeTarget,
                    mergeSources: state.mergeSources,
                    onMergeTargetSelected: viewModel.enterMerge,
                    onMergeSourceSelected: viewModel.toggleMergeSource,
                    onMergeSelectionExited: viewModel.exitMerge,
                  ),
                ),
              ),
            ),
          ],
        ),
        NamedFacetFillViewportBinder(
          scrollController: _scrollController,
          kind: kind,
        ),
        ManagementCreateEntityFab(
          facet: kind,
          horizontalPadding: horizontal,
          onPressed: () => _onCreatePressed(context, kind),
        ),
      ],
    );

    return body;
  }

  void _handleTabSelected(int index) {
    if (_selectedTabIndex == index) {
      return;
    }
    final int previousIndex = _selectedTabIndex ?? 1;
    final ManagedNamedFacetKind previousKind = metadataTabKind(previousIndex);
    ref
        .read(namedFacetManagementViewModelProvider(previousKind).notifier)
        .exitMerge();
    setState(() {
      _facetTransitionReverse = index < previousIndex;
      _selectedTabIndex = index;
      _showInlineCreateField = false;
    });
    // replace：仅改 query，保留首页 push 进来的栈，返回仍可 pop。
    context.replace('/metadata?tab=${_tabQueryForIndex(index)}');
    _scrollToContentTop();
  }

  void _scrollToContentTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      if (_scrollController.offset <= 0) {
        return;
      }
      _scrollController.jumpTo(0);
    });
  }

  Future<void> _mergeSelectedNames(ManagedNamedFacetKind kind) async {
    final NamedFacetManagementState state = ref.read(
      namedFacetManagementViewModelProvider(kind),
    );
    final String? target = state.mergeTarget;
    final List<String> sources = state.mergeSources.toList(growable: false);
    if (target == null || sources.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final bool skip = prefs.getBool(_kMergeConfirmSkipKey) ?? false;
    if (!skip && mounted) {
      final bool confirmed = await showMetadataMergeConfirmDialog(
        context: context,
        target: target,
        sourceCount: sources.length,
        onSkipChanged: (bool value) =>
            prefs.setBool(_kMergeConfirmSkipKey, value),
      );
      if (!confirmed || !mounted) {
        return;
      }
    }
    try {
      await ref
          .read(namedFacetManagementViewModelProvider(kind).notifier)
          .merge(targetName: target, sourceNames: sources);
      if (mounted) {
        showSuccessSnackbar(context, context.l10n.metadataMergeCompletedToast);
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackbar(context, error);
      }
    }
  }

  /// 新建入口：移动端（compact）弹出 Dialog；medium 及以上在 chip 流末尾内联草稿 chip。
  void _onCreatePressed(BuildContext context, ManagedNamedFacetKind kind) {
    final bool useMobileCreateDialog =
        managementCreateInteractionOf(context) ==
        ManagementCreateInteraction.mobileDialog;
    if (!useMobileCreateDialog) {
      setState(() => _showInlineCreateField = true);
      return;
    }
    unawaited(
      showManagementCreateEntityDialog(
        context: context,
        facet: kind,
        onCreate: (String name) => _addEntity(kind, name),
      ),
    );
  }

  void _commitDraftEntity(ManagedNamedFacetKind kind, String name) {
    _addEntity(kind, name);
    if (_showInlineCreateField) {
      setState(() => _showInlineCreateField = false);
    }
  }

  void _dismissDraftEntity() {
    setState(() => _showInlineCreateField = false);
  }

  void _addEntity(ManagedNamedFacetKind kind, String name) {
    unawaited(
      ref.read(namedFacetManagementViewModelProvider(kind).notifier).add(name),
    );
  }

  void _handleScrollLoadMore() {
    if (!_scrollController.hasClients) {
      return;
    }
    final ScrollPosition position = _scrollController.position;
    final ManagedNamedFacetKind kind = metadataTabKind(_selectedTabIndex ?? 1);
    final NamedFacetManagementState state = ref.read(
      namedFacetManagementViewModelProvider(kind),
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
    ref.read(namedFacetManagementViewModelProvider(kind).notifier).loadMore();
  }
}

/// 实体类型 tab 索引 → 命名元数据维度。
ManagedNamedFacetKind metadataTabKind(int index) {
  if (index < 0 || index >= kManagedNamedFacetTabOrder.length) {
    return kManagedNamedFacetTabOrder.first;
  }
  return kManagedNamedFacetTabOrder[index];
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
