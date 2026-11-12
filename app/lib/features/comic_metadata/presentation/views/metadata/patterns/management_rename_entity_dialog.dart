import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/lab_dialog_presenter.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/features/comic_metadata/public/ui/l10n/comic_metadata_l10n.dart';

const double _kManagementRenameDialogMaxWidth = 400;

/// 命名元数据重命名 Dialog（生产与 Lab 共用；经 [LabDialogPresenter] 呈现）。
Future<void> showManagementRenameEntityDialog({
  required BuildContext context,
  required ManagedNamedFacetKind facet,
  required String initialName,
  required Future<void> Function(String value) onRename,
}) {
  return LabDialogPresenter.showBasic<void>(
    context,
    dialog: _ManagementRenameEntityDialog(
      facet: facet,
      initialName: initialName,
      onRename: onRename,
    ),
  );
}

class _ManagementRenameEntityDialog extends StatefulWidget {
  const _ManagementRenameEntityDialog({
    required this.facet,
    required this.initialName,
    required this.onRename,
  });

  final ManagedNamedFacetKind facet;
  final String initialName;
  final Future<void> Function(String value) onRename;

  @override
  State<_ManagementRenameEntityDialog> createState() =>
      _ManagementRenameEntityDialogState();
}

class _ManagementRenameEntityDialogState
    extends State<_ManagementRenameEntityDialog> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmitted(String _) {
    if (!_saving) {
      _submit();
    }
  }

  Future<void> _submit() async {
    final String name = _controller.text.trim();
    if (name.isEmpty) {
      return;
    }
    if (name == widget.initialName.trim()) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onRename(name);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
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
      _kManagementRenameDialogMaxWidth,
      size.width - horizontalInset * 2,
    );

    return M3EDialog(
      title: l10n.metadataRenameTitle(widget.facet),
      content: SizedBox(
        width: contentWidth,
        child: ManagementEntityNameField(
          label: l10n.metadataNewName,
          controller: _controller,
          autofocus: true,
          onSubmitted: _handleSubmitted,
        ),
      ),
      bottomDivider: true,
      actions: <Widget>[
        M3EButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          style: M3EButtonStyle.text,
          decoration: M3EButtonDecoration(textStyle: actionLabelStyle),
          label: Text(l10n.commonCancel),
        ),
        M3EButton(
          onPressed: _saving ? null : _submit,
          style: M3EButtonStyle.filled,
          decoration: M3EButtonDecoration(textStyle: actionLabelStyle),
          label: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.commonSave),
        ),
      ],
    );
  }
}
