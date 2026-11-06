import 'dart:math' as math;

import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';

import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/lab_dialog_presenter.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/shared/ui/theme/lab_text.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/management_entity_name_field.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

const double _kManagementCreateDialogMaxWidth = 400;

/// 移动端：FAB 打开的新建实体 Dialog（outlined 字段 + 操作）。
Future<void> showManagementCreateEntityDialog({
  required BuildContext context,
  required ManagedNamedFacetKind facet,
  required ValueChanged<String> onCreate,
}) {
  return LabDialogPresenter.showBasic<void>(
    context,
    dialog: _ManagementCreateEntityDialog(facet: facet, onCreate: onCreate),
  );
}

class _ManagementCreateEntityDialog extends StatefulWidget {
  const _ManagementCreateEntityDialog({
    required this.facet,
    required this.onCreate,
  });

  final ManagedNamedFacetKind facet;
  final ValueChanged<String> onCreate;

  @override
  State<_ManagementCreateEntityDialog> createState() =>
      _ManagementCreateEntityDialogState();
}

class _ManagementCreateEntityDialogState
    extends State<_ManagementCreateEntityDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String name = _controller.text.trim();
    if (name.isEmpty) {
      return;
    }
    widget.onCreate(name);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final TextStyle actionLabelStyle = labButtonLabelStyle(
      theme,
      M3EButtonSize.sm,
    );
    final Size size = MediaQuery.sizeOf(context);
    final double horizontalInset = PageLayoutSpec.of(context).horizontalInset;
    final double contentWidth = math.min(
      _kManagementCreateDialogMaxWidth,
      size.width - horizontalInset * 2,
    );

    return M3EDialog(
      title: l10n.metadataAddLabel(widget.facet),
      content: SizedBox(
        width: contentWidth,
        child: ManagementEntityNameField(
          label: l10n.metadataAddHint(widget.facet),
          controller: _controller,
          autofocus: true,
          onSubmitted: (_) => _submit(),
        ),
      ),
      bottomDivider: true,
      actions: <Widget>[
        M3EButton(
          onPressed: () => Navigator.of(context).pop(),
          style: M3EButtonStyle.text,
          decoration: M3EButtonDecoration(textStyle: actionLabelStyle),
          label: Text(l10n.commonCancel),
        ),
        M3EButton(
          onPressed: _submit,
          style: M3EButtonStyle.filled,
          decoration: M3EButtonDecoration(textStyle: actionLabelStyle),
          label: Text(l10n.commonAdd),
        ),
      ],
    );
  }
}
