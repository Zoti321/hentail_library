import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_library_browse_page_metrics.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/dialog/md3e_lab_dialog_presenter.dart';
import 'package:hentai_library/shared/domain/repositories/named_facet_management_repository.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_management_entity_name_field.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

const double _kMd3eManagementCreateDialogMaxWidth = 400;

/// 移动端：FAB 打开的新建实体 Dialog（outlined 字段 + 操作）。
Future<void> showMd3eManagementCreateEntityDialog({
  required BuildContext context,
  required ManagedNamedFacetKind facet,
  required ValueChanged<String> onCreate,
}) {
  return Md3eLabDialogPresenter.showBasic<void>(
    context,
    dialog: _Md3eManagementCreateEntityDialog(
      facet: facet,
      onCreate: onCreate,
    ),
  );
}

class _Md3eManagementCreateEntityDialog extends StatefulWidget {
  const _Md3eManagementCreateEntityDialog({
    required this.facet,
    required this.onCreate,
  });

  final ManagedNamedFacetKind facet;
  final ValueChanged<String> onCreate;

  @override
  State<_Md3eManagementCreateEntityDialog> createState() =>
      _Md3eManagementCreateEntityDialogState();
}

class _Md3eManagementCreateEntityDialogState
    extends State<_Md3eManagementCreateEntityDialog> {
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
    final M3ESpacing spacing = theme.spacing;
    final Size size = MediaQuery.sizeOf(context);
    final Md3eWindowSizeClass sizeClass = Md3eWindowSizeClass.fromWidth(
      size.width,
    );
    final double horizontalInset =
        Md3eLibraryBrowsePageMetrics.contentHorizontalPadding(sizeClass);
    final double contentWidth = math.min(
      _kMd3eManagementCreateDialogMaxWidth,
      size.width - horizontalInset * 2,
    );

    return M3EDialog(
      title: l10n.metadataAddLabel(widget.facet),
      content: SizedBox(
        width: contentWidth,
        child: Md3eManagementEntityNameField(
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
          label: Text(l10n.commonCancel),
        ),
        M3EButton(
          onPressed: _submit,
          style: M3EButtonStyle.filled,
          label: Text(l10n.commonAdd),
        ),
      ],
    );
  }
}
