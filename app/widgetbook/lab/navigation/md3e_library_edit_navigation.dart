import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/shared/ui/layout/library_edit_form_metrics.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/motion/motion.dart';
import 'package:hentai_library/features/library_admin/presentation/views/library/library_edit_page.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/lab_dialog_presenter.dart';
import 'package:hentai_library/features/library_admin/presentation/patterns/library_edit_form.dart';

import '../../preview/md3e_library_edit_preview_data.dart';

import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_edit_actions.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/library_form.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 打开 Library 创建/编辑：compact / medium M3E 全屏；expanded+ M3E basic dialog。
Future<LibraryForm?> showLibraryEdit({
  required BuildContext context,
  required LibraryEditPageIntent intent,
  LibraryForm? initialForm,
}) {
  return _Md3eLibraryEditDialog.present(
    context,
    intent: intent,
    initialForm: initialForm,
  );
}

class _Md3eLibraryEditDialog extends StatefulWidget {
  const _Md3eLibraryEditDialog({
    super.key,
    required this.intent,
    required this.initialForm,
    required this.formOnly,
  });

  final LibraryEditPageIntent intent;
  final LibraryForm? initialForm;
  final bool formOnly;

  static Future<LibraryForm?> present(
    BuildContext context, {
    required LibraryEditPageIntent intent,
    LibraryForm? initialForm,
  }) {
    final GlobalKey<_Md3eLibraryEditDialogState> formKey =
        GlobalKey<_Md3eLibraryEditDialogState>();
    final AppLocalizations l10n = context.l10n;
    final String title = _titleForIntent(l10n, intent);

    if (LabDialogPresenter.usesFullScreenPresentation(context)) {
      return LabDialogPresenter.showFullScreen<LibraryForm>(
        context,
        title: title,
        body: _Md3eLibraryEditDialog(
          key: formKey,
          intent: intent,
          initialForm: initialForm,
          formOnly: true,
        ),
        confirmLabel: l10n.commonSave,
        onConfirm: () => formKey.currentState?._saveAndPop(),
        bottomActions: <Widget>[
          M3EButton(
            onPressed: () => Navigator.of(context).pop(),
            style: M3EButtonStyle.text,
            label: Text(l10n.commonCancel),
          ),
        ],
      );
    }

    return LabDialogPresenter.showBasic<LibraryForm>(
      context,
      dialog: _Md3eLibraryEditDialog(
        key: formKey,
        intent: intent,
        initialForm: initialForm,
        formOnly: false,
      ),
    );
  }

  static String _titleForIntent(
    AppLocalizations l10n,
    LibraryEditPageIntent intent,
  ) {
    return switch (intent) {
      LibraryEditPageIntent.createLocal => l10n.dialogCreateLocalLibraryTitle,
      LibraryEditPageIntent.createRemote => l10n.dialogCreateRemoteLibraryTitle,
      LibraryEditPageIntent.editLocal ||
      LibraryEditPageIntent.editRemote => l10n.dialogEditLibraryTitle,
    };
  }

  @override
  State<_Md3eLibraryEditDialog> createState() => _Md3eLibraryEditDialogState();
}

class _Md3eLibraryEditDialogState extends State<_Md3eLibraryEditDialog> {
  late LibraryForm _form = widget.initialForm ?? _formForIntent(widget.intent);
  LibraryFormValidation? _validation;
  bool _saving = false;

  bool get _isCreate => switch (widget.intent) {
    LibraryEditPageIntent.createLocal ||
    LibraryEditPageIntent.createRemote => true,
    LibraryEditPageIntent.editLocal ||
    LibraryEditPageIntent.editRemote => false,
  };

  static LibraryForm _formForIntent(LibraryEditPageIntent intent) {
    return switch (intent) {
      LibraryEditPageIntent.editLocal => LibraryEditPreviewData.editLocalForm(),
      LibraryEditPageIntent.editRemote =>
        LibraryEditPreviewData.editRemoteForm(),
      LibraryEditPageIntent.createLocal => LibraryForm.createLocal(),
      LibraryEditPageIntent.createRemote => LibraryForm.createRemote(),
    };
  }

  Future<void> _saveAndPop() async {
    final LibraryFormValidation validation = _form.validate(
      isCreate: _isCreate,
    );
    if (!validation.isValid) {
      setState(() => _validation = validation);
      return;
    }
    setState(() {
      _validation = null;
      _saving = true;
    });
    await Future<void>.delayed(LabMotion.labSimulatedSaveDuration);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    Navigator.of(context).pop(_form.normalized);
  }

  Widget _buildForm() {
    return LibraryEditForm(
      form: _form,
      isCreate: _isCreate,
      validation: _validation,
      enabled: !_saving,
      onFormChanged: (LibraryForm value) {
        setState(() {
          _form = value;
          if (_validation != null) {
            _validation = null;
          }
        });
      },
      onBrowseRoot: _form.isRemote ? null : () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.formOnly) {
      return SingleChildScrollView(child: _buildForm());
    }

    final AppLocalizations l10n = context.l10n;
    final double horizontalInset = PageLayoutSpec.of(context).horizontalInset;

    return M3EDialog(
      title: _Md3eLibraryEditDialog._titleForIntent(l10n, widget.intent),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: LibraryEditFormMetrics.maxWidth,
          maxHeight: MediaQuery.sizeOf(context).height * 0.55,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalInset * 0.25),
          child: _buildForm(),
        ),
      ),
      bottomDivider: true,
      actions: metadataEditDialogActions(
        context,
        onCancel: () => Navigator.of(context).pop(),
        onSave: _saving ? null : _saveAndPop,
        saving: _saving,
        saveEnabled: true,
      ),
    );
  }
}
