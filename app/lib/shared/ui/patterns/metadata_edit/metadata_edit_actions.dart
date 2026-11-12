import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

export 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_edit_save_button.dart';

/// 元数据编辑页对外能力：供 presenter 通过 [GlobalKey] 触发保存。
abstract interface class MetadataEditSaveActions {
  Future<void> saveAndPop();
}

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
    final AppLocalizations l10n = context.l10n;
    return M3EButton(
      onPressed: saving ? null : onCancel,
      style: M3EButtonStyle.text,
      label: Text(l10n.commonCancel),
    );
  }
}
