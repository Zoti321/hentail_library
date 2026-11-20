import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_catalog_query.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_library_gates.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_mutation_dialogs.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

const List<String> _imagePickerExtensions = <String>[
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'bmp',
  'avif',
];

/// 资源变更开启后的图集详情操作（目录载体；根压缩包仅提示不支持）。
class ImageSetDetailMutationSection extends ConsumerStatefulWidget {
  const ImageSetDetailMutationSection({
    super.key,
    required this.libraryId,
    required this.imageSet,
    required this.carrierShape,
  });

  final String libraryId;
  final ImageSet imageSet;
  final ImageSetCarrierShape carrierShape;

  @override
  ConsumerState<ImageSetDetailMutationSection> createState() =>
      _ImageSetDetailMutationSectionState();
}

class _ImageSetDetailMutationSectionState
    extends ConsumerState<ImageSetDetailMutationSection> {
  bool _copying = false;
  bool _takingOver = false;

  bool get _isRootArchive =>
      widget.carrierShape == ImageSetCarrierShape.rootArchive;

  Future<void> _copyImagesIn() async {
    if (_copying || _takingOver) {
      return;
    }
    final AppLocalizations l10n = context.l10n;
    final FilePickerResult? picked = await FilePicker.pickFiles(
      dialogTitle: l10n.imageSetMutationCopyPickTitle,
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: _imagePickerExtensions,
    );
    if (picked == null || !mounted) {
      return;
    }
    final List<String> paths = picked.paths
        .whereType<String>()
        .where((String path) => path.isNotEmpty)
        .toList(growable: false);
    if (paths.isEmpty) {
      return;
    }
    setState(() => _copying = true);
    try {
      await ref.read(imageSetCopyImagesInCommandProvider)(
        widget.libraryId,
        widget.imageSet.imageSetId,
        paths,
      );
    } finally {
      if (mounted) {
        setState(() => _copying = false);
      }
    }
  }

  Future<void> _takeOver() async {
    if (_copying || _takingOver) {
      return;
    }
    final bool confirmed = await confirmTakeOverImageSetManagedLayout(context);
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _takingOver = true);
    try {
      await ref.read(imageSetTakeOverManagedLayoutCommandProvider)(
        widget.libraryId,
        widget.imageSet.imageSetId,
      );
    } finally {
      if (mounted) {
        setState(() => _takingOver = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final AsyncValue<ImageSetLibraryGates> gates = ref.watch(
      imageSetLibraryGatesProvider(widget.libraryId),
    );

    return gates.when(
      data: (ImageSetLibraryGates value) {
        if (!value.resourceMutation) {
          return const SizedBox.shrink();
        }
        if (_isRootArchive) {
          return Text(
            l10n.imageSetMutationRootArchiveUnsupported,
            style: theme.typeScale.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
        }
        return Wrap(
          spacing: theme.spacing.sm,
          runSpacing: theme.spacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            M3EButton(
              onPressed: _copying || _takingOver ? null : _copyImagesIn,
              style: M3EButtonStyle.outlined,
              label: _copying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Symbols.add_photo_alternate, size: 18),
                        SizedBox(width: theme.spacing.xs),
                        Text(l10n.imageSetMutationCopyImages),
                      ],
                    ),
            ),
            if (value.managedLayout)
              M3EButton(
                onPressed: _copying || _takingOver ? null : _takeOver,
                style: M3EButtonStyle.text,
                label: _takingOver
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.imageSetMutationTakeoverAction),
              ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (Object _, StackTrace _) => const SizedBox.shrink(),
    );
  }
}