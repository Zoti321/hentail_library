import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/repositories/path_repository.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AddPathButton extends ConsumerStatefulWidget {
  const AddPathButton({super.key});

  @override
  ConsumerState<AddPathButton> createState() => _AddPathButtonState();
}

class _AddPathButtonState extends ConsumerState<AddPathButton> {
  static const double buttonIconSize = 16;
  static const double buttonHeight = 16;
  static const double buttonWidth = 16;

  bool isPicking = false;

  Future<void> addDirectory() async {
    if (isPicking) {
      return;
    }
    setState(() => isPicking = true);
    try {
      final String? directoryPath = await FilePicker.platform.getDirectoryPath();
      if (directoryPath == null || directoryPath.isEmpty) {
        return;
      }
      final PathRepository pathRepository = ref.read(pathRepoProvider);
      await pathRepository.add(directoryPath);
      if (!mounted) {
        return;
      }
      showSuccessToast(context, '已添加 1 个路径');
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return FilledButton.icon(
      onPressed: isPicking ? null : addDirectory,
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
    );
  }
}
