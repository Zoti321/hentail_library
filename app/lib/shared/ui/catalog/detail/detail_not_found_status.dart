import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/catalog/detail/detail_status_scaffold.dart';
import 'package:hentai_library/shared/ui/navigation/library_browse_navigation.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 详情未找到，附带「回到库」操作。
class DetailNotFoundStatus extends StatelessWidget {
  const DetailNotFoundStatus({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DetailStatusScaffold(
      leading: Icon(
        icon,
        size: 48,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      label: label,
      action: TextButton.icon(
        onPressed: () => goDefaultLibraryBrowseFromContext(context),
        icon: const Icon(LucideIcons.library, size: 16),
        label: Text(context.l10n.comicDetailGoToLibrary),
      ),
    );
  }
}
