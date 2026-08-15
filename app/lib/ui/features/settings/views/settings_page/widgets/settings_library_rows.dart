import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_layout_constants.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_primitives.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LibraryLocationRow extends StatelessWidget {
  const LibraryLocationRow({required this.layoutTier, super.key});

  final SettingsLayoutTier layoutTier;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final l10n = context.l10n;
    return SettingsRow(
      layoutTier: layoutTier,
      icon: Icon(
        LucideIcons.folderSearch,
        size: 20,
        color: theme.colorScheme.hentai.iconDefault,
      ),
      label: l10n.settingsLibraryLocationLabel,
      onRowTap: () => context.push('/paths'),
      action: Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: theme.colorScheme.hentai.iconSecondary,
      ),
    );
  }
}

class SupportedFormatsRow extends StatelessWidget {
  const SupportedFormatsRow({required this.layoutTier, super.key});

  final SettingsLayoutTier layoutTier;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final l10n = context.l10n;
    return SettingsRow(
      layoutTier: layoutTier,
      icon: Icon(
        LucideIcons.files,
        size: 20,
        color: theme.colorScheme.hentai.iconDefault,
      ),
      label: l10n.settingsSupportedFormatsLabel,
      onRowTap: () => context.push('/settings/formats'),
      action: Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: theme.colorScheme.hentai.iconSecondary,
      ),
    );
  }
}
