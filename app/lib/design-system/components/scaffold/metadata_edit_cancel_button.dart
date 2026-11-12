import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../l10n/design_system_localizations.dart';

/// 元数据 / Library 编辑 M3EDialog 底部 Cancel 按钮。
class MetadataEditCancelButton extends StatelessWidget {
  const MetadataEditCancelButton({
    super.key,
    required this.onCancel,
    required this.saving,
  });

  final VoidCallback? onCancel;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final DesignSystemLocalizations l10n = DesignSystemLocalizations.of(
      context,
    );
    return M3EButton(
      onPressed: saving ? null : onCancel,
      style: M3EButtonStyle.text,
      label: Text(l10n.cancelLabel),
    );
  }
}
