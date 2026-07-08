import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_scroll_to_top_button.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/author_management_panel.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/metadata_content_search.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/metadata_layout_constants.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/metadata_page_header.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/tag_management_panel.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/tag_name_editor_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
  }

  @override
  void dispose() {
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
              final double horizontalPadding =
                  metadataContentHorizontalPadding(layoutTier);
              final double innerMaxWidth = metadataInnerContentMaxWidth(
                layoutTier,
                viewportWidth,
              );

              if (metadataUsesPageScroll(layoutTier)) {
                return _buildCompactPage(
                  layoutTier: layoutTier,
                  horizontalPadding: horizontalPadding,
                  innerMaxWidth: innerMaxWidth,
                  selectedIndex: selectedIndex,
                );
              }

              return _buildWidePage(
                layoutTier: layoutTier,
                horizontalPadding: horizontalPadding,
                innerMaxWidth: innerMaxWidth,
                selectedIndex: selectedIndex,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCompactPage({
    required MetadataLayoutTier layoutTier,
    required double horizontalPadding,
    required double innerMaxWidth,
    required int selectedIndex,
  }) {
    final Widget headerSection = MetadataPageHeaderSection(
      layoutTier: layoutTier,
      horizontalPadding: horizontalPadding,
      selectedTabIndex: selectedIndex,
      onTabSelected: _handleTabSelected,
      onAdd: () => _invokeAddForTab(context, selectedIndex),
    );
    final Widget header = KeyedSubtree(
      key: _headerMeasureKey,
      child: headerSection,
    );

    return Stack(
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
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: innerMaxWidth,
                  child: MetadataContentSearch(
                    layoutTier: layoutTier,
                    selectedTabIndex: selectedIndex,
                    contentMaxWidth: innerMaxWidth,
                  ),
                ),
              ),
            ),
            if (_visitedTabIndexes.contains(selectedIndex))
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                sliver: switch (selectedIndex) {
                  0 => const AuthorManagementSliverGroup(),
                  1 => const TagManagementSliverGroup(),
                  _ => const TagManagementSliverGroup(),
                },
              ),
          ],
        ),
        LibraryScrollToTopButton(
          scrollController: _scrollController,
          isDrawerOpen: false,
        ),
      ],
    );
  }

  Widget _buildWidePage({
    required MetadataLayoutTier layoutTier,
    required double horizontalPadding,
    required double innerMaxWidth,
    required int selectedIndex,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        MetadataPageHeaderSection(
          layoutTier: layoutTier,
          horizontalPadding: horizontalPadding,
          selectedTabIndex: selectedIndex,
          onTabSelected: _handleTabSelected,
          onAdd: () => _invokeAddForTab(context, selectedIndex),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: innerMaxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  MetadataContentSearch(
                    layoutTier: layoutTier,
                    selectedTabIndex: selectedIndex,
                    contentMaxWidth: innerMaxWidth,
                  ),
                  Expanded(
                    child: _visitedTabIndexes.contains(selectedIndex)
                        ? switch (selectedIndex) {
                            0 => AuthorManagementPanel(
                              layoutTier: layoutTier,
                            ),
                            1 => TagManagementPanel(layoutTier: layoutTier),
                            _ => TagManagementPanel(layoutTier: layoutTier),
                          }
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleTabSelected(int index) {
    if (_selectedTabIndex == index) {
      return;
    }
    setState(() {
      _selectedTabIndex = index;
    });
    _scrollToContentTop();
  }

  Future<void> _invokeAddForTab(BuildContext context, int tabIndex) async {
    switch (tabIndex) {
      case 0:
        await _openAddAuthorDialog(context);
        break;
      case 1:
        await _openAddTagDialog(context);
        break;
      default:
        break;
    }
  }

  Future<void> _openAddTagDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => TagNameEditorDialog(
        title: '添加标签',
        labelText: '名称',
        hintText: '输入标签名称…',
        initialValue: '',
        onSubmit: (String value) async {
          await ref.read(tagActionsProvider).addTag(Tag(name: value));
        },
      ),
    );
  }

  Future<void> _openAddAuthorDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => TagNameEditorDialog(
        title: '添加作者',
        labelText: '名称',
        hintText: '输入作者名称…',
        initialValue: '',
        onSubmit: (String value) async {
          await ref.read(authorActionsProvider).addAuthor(Author(name: value));
        },
      ),
    );
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
    default:
      return 1;
  }
}
