import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

Future<String?> showImageSetSubmissionNameDialog({
  required BuildContext context,
  required String title,
  required String fieldLabel,
  String initialName = '',
}) async {
  return LabDialogPresenter.showBasic<String>(
    context,
    dialog: _ImageSetSubmissionNameDialog(
      title: title,
      fieldLabel: fieldLabel,
      initialName: initialName,
    ),
  );
}

class _ImageSetSubmissionNameDialog extends StatefulWidget {
  const _ImageSetSubmissionNameDialog({
    required this.title,
    required this.fieldLabel,
    required this.initialName,
  });

  final String title;
  final String fieldLabel;
  final String initialName;

  @override
  State<_ImageSetSubmissionNameDialog> createState() =>
      _ImageSetSubmissionNameDialogState();
}

class _ImageSetSubmissionNameDialogState
    extends State<_ImageSetSubmissionNameDialog> {
  late final TextEditingController _controller;

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

  void _submit() {
    final String value = _controller.text.trim();
    if (value.isEmpty) {
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool canSave = _controller.text.trim().isNotEmpty;

    return M3EDialog(
      title: widget.title,
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.fieldLabel),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
      ),
      bottomDivider: true,
      actions: <Widget>[
        DialogActionBar(
          onCancel: () => Navigator.of(context).pop(),
          onConfirm: _submit,
          confirmEnabled: canSave,
          cancelLabel: l10n.commonCancel,
          confirmLabel: l10n.commonSave,
        ),
      ],
    );
  }
}

Future<bool> showImageSetSubmissionDeleteConfirmDialog({
  required BuildContext context,
  required String submissionName,
}) async {
  final AppLocalizations l10n = context.l10n;
  return showConfirmDialog(
    context,
    title: l10n.imageSetSubmissionDeleteTitle,
    content: Text(l10n.imageSetSubmissionDeleteBody(submissionName)),
    confirmLabel: l10n.commonDelete,
    destructive: true,
  );
}