import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/settings_page/widgets/settings_page_primitives.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AboutVersionRow extends StatelessWidget {
  const AboutVersionRow({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SettingsRow(
      icon: Icon(
        LucideIcons.info,
        size: 20,
        color: theme.colorScheme.hentai.iconDefault,
      ),
      label: '版本',
      description: 'v1.0.0',
      action: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.hentai.inputBackgroundDisabled,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '检查更新',
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.hentai.textTertiary,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
