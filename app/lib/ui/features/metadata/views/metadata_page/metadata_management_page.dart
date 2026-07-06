import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/author_management_panel.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/series_management_panel.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/tag_management_panel.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/rename_tag_dialog.dart';
import 'package:hentai_library/ui/core/widgets/chrome/capsule_tab_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  int? _selectedTabIndex;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: tokens.layout.contentAreaPadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    CapsuleTabBar(
                      items: const <CapsuleTabItem>[
                        CapsuleTabItem(label: '作者', icon: LucideIcons.penLine),
                        CapsuleTabItem(label: '标签', icon: LucideIcons.tags),
                        CapsuleTabItem(label: '系列', icon: LucideIcons.layers),
                      ],
                      selectedIndex: selectedIndex,
                      onSelected: (int index) {
                        if (_selectedTabIndex == index) {
                          return;
                        }
                        setState(() {
                          _selectedTabIndex = index;
                        });
                      },
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Text(
                        '管理作者、标签与系列',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.hentai.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildSelectedTabPanel(selectedIndex)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabPanel(int selectedIndex) {
    if (!_visitedTabIndexes.contains(selectedIndex)) {
      return const SizedBox.shrink();
    }
    switch (selectedIndex) {
      case 0:
        return const AuthorManagementPanel();
      case 1:
        return const TagManagementPanel();
      case 2:
        return const SeriesManagementPanel();
      default:
        return const TagManagementPanel();
    }
  }

  Future<void> _invokeAddForTab(BuildContext context, int tabIndex) async {
    switch (tabIndex) {
      case 0:
        await _openAddAuthorDialog(context);
        break;
      case 1:
        await _openAddTagDialog(context);
        break;
      case 2:
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
    case 'series':
      return 2;
    default:
      return 1;
  }
}
