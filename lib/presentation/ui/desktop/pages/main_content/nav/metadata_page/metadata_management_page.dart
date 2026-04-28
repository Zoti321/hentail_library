import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:hentai_library/model/entity/comic/author.dart';
import 'package:hentai_library/model/entity/comic/tag.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/metadata_page/widgets/author_management_panel.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/metadata_page/widgets/series_management_panel.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/metadata_page/widgets/tag_management_panel.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/actions/ghost_button.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/chrome/capsule_tab_bar.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/dialog/add_series_dialog.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/dialog/rename_tag_dialog.dart';
import 'package:hentai_library/services/metadata/metadata_io_exception.dart';
import 'package:hentai_library/services/metadata/metadata_io_models.dart';
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
  bool _isExecutingMetadataIo = false;
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
                        style: TextStyle(fontSize: 13, color: cs.textTertiary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GhostButton.iconText(
                      icon: LucideIcons.fileUp,
                      text: _isExecutingMetadataIo ? '导入中…' : '导入 JSON',
                      tooltip: '',
                      semanticLabel: '导入元数据 JSON',
                      onPressed: _isExecutingMetadataIo
                          ? null
                          : () => _handleImportMetadata(),
                      delayTooltipThreeSeconds: false,
                    ),
                    const SizedBox(width: 4),
                    GhostButton.iconText(
                      icon: LucideIcons.fileDown,
                      text: _isExecutingMetadataIo ? '导出中…' : '导出 JSON',
                      tooltip: '',
                      semanticLabel: '导出元数据 JSON',
                      onPressed: _isExecutingMetadataIo
                          ? null
                          : () => _handleExportMetadata(),
                      delayTooltipThreeSeconds: false,
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
        await _openAddSeriesDialog(context);
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

  Future<void> _openAddSeriesDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AddSeriesDialog(
        onCreated: () {
          showSuccessToast(context, '系列创建成功');
        },
      ),
    );
  }

  Future<void> _handleImportMetadata() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['json'],
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final String? filePath = result.files.first.path;
    if (filePath == null || filePath.isEmpty) {
      return;
    }
    await _executeMetadataIo(
      action: () async {
        final report = await ref
            .read(metadataImportExportServiceProvider)
            .importFromJsonFile(filePath);
        return _buildImportSummary(report);
      },
      successMessage: '元数据导入成功',
    );
  }

  Future<void> _handleExportMetadata() async {
    final String? selectedPath = await FilePicker.platform.saveFile(
      dialogTitle: '导出元数据',
      fileName: 'metadata_export.json',
      type: FileType.custom,
      allowedExtensions: const <String>['json'],
    );
    if (selectedPath == null || selectedPath.isEmpty) {
      return;
    }
    String targetPath = selectedPath;
    if (!targetPath.toLowerCase().endsWith('.json')) {
      targetPath = '$targetPath.json';
    }
    await _executeMetadataIo(
      action: () async {
        final File outputFile = File(targetPath);
        if (!await outputFile.parent.exists()) {
          await outputFile.parent.create(recursive: true);
        }
        await ref
            .read(metadataImportExportServiceProvider)
            .exportToJsonFile(targetFilePath: targetPath);
        return '元数据导出成功';
      },
      successMessage: '元数据导出成功',
    );
  }

  Future<void> _executeMetadataIo({
    required Future<String> Function() action,
    required String successMessage,
  }) async {
    if (_isExecutingMetadataIo) {
      return;
    }
    setState(() {
      _isExecutingMetadataIo = true;
    });
    try {
      final String message = await action();
      if (!mounted) {
        return;
      }
      showSuccessToast(context, message.isEmpty ? successMessage : message);
    } on MetadataIoFormatException {
      if (!mounted) {
        return;
      }
      showErrorToast(context, '格式不符合');
    } on MetadataImportException catch (error) {
      if (!mounted) {
        return;
      }
      showErrorToast(context, error.message);
    } on MetadataExportException catch (error) {
      if (!mounted) {
        return;
      }
      showErrorToast(context, error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showErrorToast(context, error);
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isExecutingMetadataIo = false;
      });
    }
  }

  String _buildImportSummary(MetadataImportReport report) {
    return '元数据导入完成\n'
        '作者：新增 ${report.addedAuthors}，跳过 ${report.skippedAuthors}\n'
        '标签：新增 ${report.addedTags}，跳过 ${report.skippedTags}\n'
        '系列：新增 ${report.addedSeries}，跳过 ${report.skippedSeries}\n'
        '系列项：写入 ${report.writtenSeriesItems}，'
        '未匹配漫画 ${report.skippedSeriesItemsMissingComic}，'
        '已有归属 ${report.skippedSeriesItemsOccupied}，'
        '顺序冲突/已存在 ${report.skippedSeriesItemsOrderConflict}';
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

