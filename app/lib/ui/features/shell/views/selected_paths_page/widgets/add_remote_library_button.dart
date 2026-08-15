import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/library_form_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AddRemoteLibraryButton extends ConsumerWidget {
  const AddRemoteLibraryButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final l10n = context.l10n;

    return OutlinedButton.icon(
      onPressed: () => showLibraryFormDialog(
        context: context,
        mode: LibraryFormMode.createRemote,
      ),
      icon: const Icon(LucideIcons.cloudUpload, size: 16),
      label: Text(l10n.remoteLibraryAddButton),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
