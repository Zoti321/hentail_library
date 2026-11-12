import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 元数据 / Library 编辑 M3EDialog 底部 Save 按钮（保存中显示进度）。
class MetadataEditSaveButton extends StatelessWidget {
  const MetadataEditSaveButton({
    super.key,
    required this.onSave,
    required this.saving,
    required this.saveEnabled,
  });

  final VoidCallback? onSave;
  final bool saving;
  final bool saveEnabled;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    return M3EButton(
      onPressed: saving || !saveEnabled ? null : onSave,
      style: M3EButtonStyle.filled,
      label: saving
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onPrimary,
              ),
            )
          : Text(l10n.commonSave),
    );
  }
}
