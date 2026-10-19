import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/actions/ghost_button.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/terminal_spinner.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/comic_metadata_bulk_patch_controller.dart';

/// Shell-global bulk metadata patch busy strip.
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
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.primary.withValues(alpha: 0.08),
      child: Container(
        width: double.infinity,
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: context.hentai.borderSubtle),
          ),
        ),
        child: Row(
          children: <Widget>[
            TerminalSpinner(color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.bulkEditMetadataBusy(count),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.hentai.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GhostButton.text(
              text: l10n.bulkEditMetadataCancelBatch,
              onPressed: () => ref
                  .read(comicMetadataBulkPatchControllerProvider.notifier)
                  .cancel(),
            ),
          ],
        ),
      ),
    );
  }
}
