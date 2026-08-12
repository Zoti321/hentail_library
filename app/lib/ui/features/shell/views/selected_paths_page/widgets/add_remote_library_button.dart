import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/repositories/library_repository.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/remote_library_form_dialog.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AddRemoteLibraryButton extends HookConsumerWidget {
  const AddRemoteLibraryButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final l10n = context.l10n;
    final ValueNotifier<bool> busy = useState(false);

    Future<void> addRemote() async {
      if (busy.value) {
        return;
      }
      final RemoteLibraryFormResult? result = await showRemoteLibraryFormDialog(
        context: context,
      );
      if (result == null || !context.mounted) {
        return;
      }
      busy.value = true;
      try {
        final LibraryRepository repo = ref.read(libraryRepoProvider);
        await repo.createRemote(
          rootUrl: result.rootUrl,
          username: result.username,
          password: result.password,
          allowHttp: result.allowHttp,
        );
        await ref.read(currentLibraryProvider.notifier).refresh();
        ref.read(libraryRevisionProvider.notifier).notifyExternalChange();
        if (!context.mounted) {
          return;
        }
        showSuccessToast(context, l10n.remoteLibraryAddedToast);
      } catch (error) {
        if (!context.mounted) {
          return;
        }
        showErrorToast(context, error);
      } finally {
        if (context.mounted) {
          busy.value = false;
        }
      }
    }

    return OutlinedButton.icon(
      onPressed: busy.value ? null : addRemote,
      icon: busy.value
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(LucideIcons.cloudUpload, size: 16),
      label: Text(busy.value ? l10n.shellProcessing : l10n.remoteLibraryAddButton),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
