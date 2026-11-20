import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_submission.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

Future<String?> showImageSetSubmissionNameDialog({
  required BuildContext context,
  required String title,
  required String fieldLabel,
  String initialName = '',
  bool requireNonEmptyName = false,
}) async {
  return LabDialogPresenter.showBasic<String>(
    context,
    dialog: _ImageSetSubmissionNameDialog(
      title: title,
      fieldLabel: fieldLabel,
      initialName: initialName,
      requireNonEmptyName: requireNonEmptyName,
    ),
  );
}

class _ImageSetSubmissionNameDialog extends StatefulWidget {
  const _ImageSetSubmissionNameDialog({
    required this.title,
    required this.fieldLabel,
    required this.initialName,
    required this.requireNonEmptyName,
  });

  final String title;
  final String fieldLabel;
  final String initialName;
  final bool requireNonEmptyName;

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
    if (widget.requireNonEmptyName && value.isEmpty) {
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool trimmedNonempty = _controller.text.trim().isNotEmpty;
    final bool confirmEnabled =
        !widget.requireNonEmptyName || trimmedNonempty;

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
          confirmEnabled: confirmEnabled,
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

Future<ImageSetSubmission?> showImageSetPickSubmissionDialog({
  required BuildContext context,
  required List<ImageSetSubmission> submissions,
}) {
  final AppLocalizations l10n = context.l10n;
  return LabDialogPresenter.showBasic<ImageSetSubmission>(
    context,
    dialog: M3EDialog(
      title: l10n.imageSetDetailPickSubmissionTitle,
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: submissions.length,
          itemBuilder: (BuildContext context, int index) {
            final ImageSetSubmission submission = submissions[index];
            return ListTile(
              title: Text(submission.name),
              onTap: () => Navigator.of(context).pop(submission),
            );
          },
        ),
      ),
      actions: <Widget>[
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
        ),
      ],
    ),
  );
}