import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_library_edit_form_metrics.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:hentai_library/md3e/pages/md3e_library_edit_page.dart';
import 'package:hentai_library/md3e/patterns/dialog/md3e_lab_dialog_presenter.dart';
import 'package:hentai_library/md3e/patterns/library_admin/md3e_library_edit_form.dart';
import 'package:hentai_library/md3e/patterns/library_admin/md3e_library_edit_preview_data.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_metadata_edit_actions.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/library_form.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 打开 Library 创建/编辑：compact / medium M3E 全屏；expanded+ M3E basic dialog。
Future<LibraryForm?> showMd3eLibraryEdit({
  required BuildContext context,
  required Md3eLibraryEditPageIntent intent,
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

  final Md3eLibraryEditPageIntent intent;
  final LibraryForm? initialForm;
  final bool formOnly;

  static Future<LibraryForm?> present(
    BuildContext context, {
    required Md3eLibraryEditPageIntent intent,
    LibraryForm? initialForm,
  }) {
    final GlobalKey<_Md3eLibraryEditDialogState> formKey =
        GlobalKey<_Md3eLibraryEditDialogState>();
    final AppLocalizations l10n = context.l10n;
    final String title = _titleForIntent(l10n, intent);

    if (Md3eLabDialogPresenter.usesFullScreenPresentation(context)) {
      return Md3eLabDialogPresenter.showFullScreen<LibraryForm>(
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

    return Md3eLabDialogPresenter.showBasic<LibraryForm>(
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
    Md3eLibraryEditPageIntent intent,
  ) {
    return switch (intent) {
      Md3eLibraryEditPageIntent.createLocal =>
        l10n.dialogCreateLocalLibraryTitle,
      Md3eLibraryEditPageIntent.createRemote =>
        l10n.dialogCreateRemoteLibraryTitle,
      Md3eLibraryEditPageIntent.editLocal ||
      Md3eLibraryEditPageIntent.editRemote =>
        l10n.dialogEditLibraryTitle,
    };
  }

  @override
  State<_Md3eLibraryEditDialog> createState() => _Md3eLibraryEditDialogState();
}

class _Md3eLibraryEditDialogState extends State<_Md3eLibraryEditDialog> {
  late LibraryForm _form =
      widget.initialForm ?? _formForIntent(widget.intent);
  LibraryFormValidation? _validation;
  bool _saving = false;

  bool get _isCreate => switch (widget.intent) {
        Md3eLibraryEditPageIntent.createLocal ||
        Md3eLibraryEditPageIntent.createRemote =>
          true,
        Md3eLibraryEditPageIntent.editLocal ||
        Md3eLibraryEditPageIntent.editRemote =>
          false,
      };

  static LibraryForm _formForIntent(Md3eLibraryEditPageIntent intent) {
    return switch (intent) {
      Md3eLibraryEditPageIntent.editLocal =>
        Md3eLibraryEditPreviewData.editLocalForm(),
      Md3eLibraryEditPageIntent.editRemote =>
        Md3eLibraryEditPreviewData.editRemoteForm(),
      Md3eLibraryEditPageIntent.createLocal => LibraryForm.createLocal(),
      Md3eLibraryEditPageIntent.createRemote => LibraryForm.createRemote(),
    };
  }

  Future<void> _saveAndPop() async {
    final LibraryFormValidation validation = _form.validate(isCreate: _isCreate);
    if (!validation.isValid) {
      setState(() => _validation = validation);
      return;
    }
    setState(() {
      _validation = null;
      _saving = true;
    });
    await Future<void>.delayed(Md3eMotion.labSimulatedSaveDuration);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    Navigator.of(context).pop(_form.normalized);
  }

  Widget _buildForm() {
    return Md3eLibraryEditForm(
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
      return SingleChildScrollView(
        child: _buildForm(),
      );
    }

    final AppLocalizations l10n = context.l10n;
    final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);
    final double horizontalInset =
        Md3eLibraryEditFormMetrics.contentHorizontalPadding(sizeClass);

    return M3EDialog(
      title: _Md3eLibraryEditDialog._titleForIntent(l10n, widget.intent),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Md3eLibraryEditFormMetrics.maxWidth,
          maxHeight: MediaQuery.sizeOf(context).height * 0.55,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalInset * 0.25),
          child: _buildForm(),
        ),
      ),
      bottomDivider: true,
      actions: md3eMetadataEditDialogActions(
        context,
        onCancel: () => Navigator.of(context).pop(),
        onSave: _saving ? null : _saveAndPop,
        saving: _saving,
        saveEnabled: true,
      ),
    );
  }
}
