import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/comic_metadata_bulk_patch_controller.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Shell-global bulk metadata patch busy strip（MD3E）。
class ComicMetadataBulkPatchShellFeedback extends ConsumerWidget {
  const ComicMetadataBulkPatchShellFeedback({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool running = ref.watch(
      comicMetadataBulkPatchControllerProvider.select((s) => s.running),
    );
    if (!running) {
      return const SizedBox.shrink();
    }

    final int count = ref.watch(
      comicMetadataBulkPatchControllerProvider.select((s) => s.comicCount),
    );
    final l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final TextStyle labelStyle = theme.typeScale.labelMedium.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w500,
    );

    return Material(
      color: scheme.primary.withValues(alpha: 0.08),
      child: Container(
        width: double.infinity,
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 14,
              height: 14,
              child: M3EProgressIndicator.circular(
                size: 14,
                strokeWidth: 2,
                color: scheme.primary,
                showTrack: false,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.bulkEditMetadataBusy(count),
                style: labelStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            M3EButton(
              onPressed: () => ref
                  .read(comicMetadataBulkPatchControllerProvider.notifier)
                  .cancel(),
              style: M3EButtonStyle.text,
              size: M3EButtonSize.sm,
              label: Text(l10n.bulkEditMetadataCancelBatch),
            ),
          ],
        ),
      ),
    );
  }
}
