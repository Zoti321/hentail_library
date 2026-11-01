import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/library_edit_form_metrics.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/motion/motion.dart';
import 'package:hentai_library/features/library_admin/presentation/patterns/library_edit_form.dart';
import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_edit_surface.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/library_form.dart';

/// Lab 中 Library 编辑页的打开意图（Widgetbook / 路由）。
enum Md3eLibraryEditPageIntent {
  editLocal,
  editRemote,
  createLocal,
  createRemote,
}

/// Library 创建/编辑 Lab 页（Widgetbook / 路由）。
class Md3eLibraryEditPage extends StatefulWidget {
  const Md3eLibraryEditPage({
    super.key,
    this.intent = Md3eLibraryEditPageIntent.editLocal,
    required this.initialForm,
    this.presentation = Md3eMetadataEditPresentation.embedded,
    this.onSaved,
    this.onCancel,
  });

  final Md3eLibraryEditPageIntent intent;
  final LibraryForm initialForm;
  final Md3eMetadataEditPresentation presentation;
  final ValueChanged<LibraryForm>? onSaved;
  final VoidCallback? onCancel;

  @override
  State<Md3eLibraryEditPage> createState() => _Md3eLibraryEditPageState();
}

class _Md3eLibraryEditPageState extends State<Md3eLibraryEditPage> {
  late LibraryForm _form = widget.initialForm;
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

  String _title(AppLocalizations l10n) {
    return switch (widget.intent) {
      Md3eLibraryEditPageIntent.createLocal =>
        l10n.dialogCreateLocalLibraryTitle,
      Md3eLibraryEditPageIntent.createRemote =>
        l10n.dialogCreateRemoteLibraryTitle,
      Md3eLibraryEditPageIntent.editLocal ||
      Md3eLibraryEditPageIntent.editRemote =>
        l10n.dialogEditLibraryTitle,
    };
  }

  void _handleCancel() {
    widget.onCancel?.call();
    if (widget.onCancel == null && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleSave() async {
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
    widget.onSaved?.call(_form.normalized);
    setState(() => _saving = false);
    if (widget.onSaved == null && Navigator.canPop(context)) {
      Navigator.of(context).pop(_form.normalized);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Md3eMetadataEditSurface(
      presentation: widget.presentation,
      maxWidth: Md3eLibraryEditFormMetrics.maxWidth,
      title: _title(l10n),
      onCancel: _handleCancel,
      onSave: _handleSave,
      saving: _saving,
      body: Md3eLibraryEditForm(
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
        onBrowseRoot: _form.isRemote ? null : _browseLocalRoot,
      ),
    );
  }

  void _browseLocalRoot() {
    // Lab：仅占位，不打开系统目录选择器。
  }
}
