import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_catalog_query.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_library_gates.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_mutation_dialogs.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Secondary mutation chrome under the detail header (takeover / root-archive note).
/// Copy-in lives on the detail trailing tonal add control.
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
  bool _takingOver = false;

  bool get _isRootArchive =>
      widget.carrierShape == ImageSetCarrierShape.rootArchive;

  Future<void> _takeOver() async {
    if (_takingOver) {
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
        if (!value.managedLayout) {
          return const SizedBox.shrink();
        }
        return M3EButton(
          onPressed: _takingOver ? null : _takeOver,
          style: M3EButtonStyle.text,
          label: _takingOver
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.imageSetMutationTakeoverAction),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (Object _, StackTrace _) => const SizedBox.shrink(),
    );
  }
}
