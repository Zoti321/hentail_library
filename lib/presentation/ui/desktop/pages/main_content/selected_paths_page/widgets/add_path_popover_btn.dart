import 'dart:io' show Platform;

import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/repository/path_repository.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AddPathPopoverButton extends ConsumerStatefulWidget {
  const AddPathPopoverButton({super.key});

  @override
  ConsumerState<AddPathPopoverButton> createState() =>
      _AddPathPopoverButtonState();
}

class _AddPathPopoverButtonState extends ConsumerState<AddPathPopoverButton> {
  static const double menuVerticalMargin = -26;
  static const double buttonIconSize = 16;
  static const double buttonHeight = 16;
  static const double buttonWidth = 16;

  final CustomPopupMenuController menuController = CustomPopupMenuController();
  bool isPicking = false;

  Future<void> executePickingTask(Future<void> Function() task) async {
    if (isPicking) {
      return;
    }
    setState(() => isPicking = true);
    try {
      await task();
    } catch (error) {
      if (!mounted) {
        return;
      }
      showErrorToast(context, error);
    } finally {
      if (mounted) {
        setState(() => isPicking = false);
      }
    }
  }

  Future<int> savePickedPaths(List<String> paths) async {
    final PathRepository pathRepository = ref.read(pathRepoProvider);
    int addedCount = 0;
    for (final String path in paths) {
      if (path.isEmpty) {
        continue;
      }
      await pathRepository.add(path);
      addedCount++;
    }
    return addedCount;
  }

  void showAddResultToast(int addedCount) {
    if (!mounted || addedCount == 0) {
      return;
    }
    showSuccessToast(
      context,
      addedCount == 1 ? '已添加 1 个路径' : '已添加 $addedCount 个路径',
    );
  }

  Future<void> pickAndSavePaths(Future<List<String>> Function() picker) async {
    await executePickingTask(() async {
      final List<String> paths = await picker();
      if (paths.isEmpty) {
        return;
      }
      final int addedCount = await savePickedPaths(paths);
      showAddResultToast(addedCount);
    });
  }

  Future<List<String>> pickFilePaths() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
      allowCompression: false,
    );
    if (result == null || result.files.isEmpty) {
      return const <String>[];
    }
    return result.files
        .map((PlatformFile file) => file.path)
        .whereType<String>()
        .toList();
  }

  Future<List<String>> pickFolderPaths() async {
    final String? directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath == null || directoryPath.isEmpty) {
      return const <String>[];
    }
    return <String>[directoryPath];
  }

  Future<List<String>> pickMixedPathsMac() async {
    if (!Platform.isMacOS) {
      return const <String>[];
    }
    final List<String>? paths = await FilePicker.platform
        .pickFileAndDirectoryPaths(type: FileType.any);
    if (paths == null || paths.isEmpty) {
      return const <String>[];
    }
    return paths;
  }

  Future<void> addFiles() async {
    await pickAndSavePaths(pickFilePaths);
  }

  Future<void> addFolder() async {
    await pickAndSavePaths(pickFolderPaths);
  }

  Future<void> pickMixedMac() async {
    await pickAndSavePaths(pickMixedPathsMac);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return CustomPopupMenu(
      controller: menuController,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: menuVerticalMargin,
      menuBuilder: () => _AddPathMenuPanel(
        isPicking: isPicking,
        onPickMixed: () {
          menuController.hideMenu();
          pickMixedMac();
        },
        onAddFiles: () {
          menuController.hideMenu();
          addFiles();
        },
        onAddFolder: () {
          menuController.hideMenu();
          addFolder();
        },
      ),
      child: FilledButton.icon(
        onPressed: isPicking ? null : () => menuController.toggleMenu(),
        icon: isPicking
            ? const SizedBox(
                width: buttonWidth,
                height: buttonHeight,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(LucideIcons.plus, size: buttonIconSize),
        label: Text(isPicking ? '处理中…' : '添加路径'),
        style: FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _AddPathMenuPanel extends StatelessWidget {
  const _AddPathMenuPanel({
    required this.isPicking,
    required this.onPickMixed,
    required this.onAddFiles,
    required this.onAddFolder,
  });

  final bool isPicking;
  final VoidCallback onPickMixed;
  final VoidCallback onAddFiles;
  final VoidCallback onAddFolder;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        border: Border.all(color: colorScheme.hentai.borderSubtle),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.hentai.cardShadowHover,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (Platform.isMacOS) ...<Widget>[
              _AddPathMenuItem(
                icon: LucideIcons.layers,
                title: '混合选择…',
                subtitle: '文件与文件夹',
                enabled: !isPicking,
                onPressed: onPickMixed,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sm),
                child: Divider(height: 1, color: colorScheme.hentai.borderSubtle),
              ),
            ],
            _AddPathMenuItem(
              icon: LucideIcons.fileStack,
              title: '添加文件',
              subtitle: '可多选',
              enabled: !isPicking,
              onPressed: onAddFiles,
            ),
            _AddPathMenuItem(
              icon: LucideIcons.folderOpen,
              title: '添加文件夹',
              subtitle: '选择目录',
              enabled: !isPicking,
              onPressed: onAddFolder,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPathMenuItem extends StatelessWidget {
  const _AddPathMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Material(
      child: InkWell(
        hoverColor: colorScheme.primary.withAlpha(10),
        onTap: enabled ? onPressed : null,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacing.md,
            vertical: tokens.spacing.sm,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 20,
                color: enabled
                    ? colorScheme.primary
                    : colorScheme.hentai.textTertiary,
              ),
              SizedBox(width: tokens.spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: tokens.text.bodySm,
                        fontWeight: FontWeight.w600,
                        color: enabled
                            ? colorScheme.hentai.textPrimary
                            : colorScheme.hentai.textDisabled,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: tokens.text.labelXs,
                        color: colorScheme.hentai.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
