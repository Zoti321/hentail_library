import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/library_edit_form_metrics.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/library_admin/presentation/patterns/library_edit_form.dart';
import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_edit_surface.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/library_form.dart';

/// Widgetbook 中 Library 编辑页的打开意图。
///
/// 生产路径走 `showLibraryFormDialog`；两者共用 [LibraryEditForm]。
enum LibraryEditPageIntent { editLocal, editRemote, createLocal, createRemote }

/// Library 创建/编辑 **Lab / Widgetbook** 页（不挂生产路由）。
///
/// 表单字段与生产 Dialog 共用 [LibraryEditForm]；保存为模拟延迟，目录选择为占位。
class LibraryEditPage extends StatefulWidget {
  const LibraryEditPage({
    super.key,
    this.intent = LibraryEditPageIntent.editLocal,
    required this.initialForm,
    this.presentation = MetadataEditPresentation.embedded,
    this.onSaved,
    this.onCancel,
  });

  final LibraryEditPageIntent intent;
  final LibraryForm initialForm;
  final MetadataEditPresentation presentation;
  final ValueChanged<LibraryForm>? onSaved;
  final VoidCallback? onCancel;

  @override
  State<LibraryEditPage> createState() => _LibraryEditPageState();
}

class _LibraryEditPageState extends State<LibraryEditPage> {
  late LibraryForm _form = widget.initialForm;
  LibraryFormValidation? _validation;
  bool _saving = false;

  bool get _isCreate => switch (widget.intent) {
    LibraryEditPageIntent.createLocal ||
    LibraryEditPageIntent.createRemote => true,
    LibraryEditPageIntent.editLocal ||
    LibraryEditPageIntent.editRemote => false,
  };

  String _title(AppLocalizations l10n) {
    return switch (widget.intent) {
      LibraryEditPageIntent.createLocal => l10n.dialogCreateLocalLibraryTitle,
      LibraryEditPageIntent.createRemote => l10n.dialogCreateRemoteLibraryTitle,
      LibraryEditPageIntent.editLocal ||
      LibraryEditPageIntent.editRemote => l10n.dialogEditLibraryTitle,
    };
  }

  void _handleCancel() {
    widget.onCancel?.call();
    if (widget.onCancel == null && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleSave() async {
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
    widget.onSaved?.call(_form.normalized);
    setState(() => _saving = false);
    if (widget.onSaved == null && Navigator.canPop(context)) {
      Navigator.of(context).pop(_form.normalized);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return MetadataEditSurface(
      presentation: widget.presentation,
      maxWidth: LibraryEditFormMetrics.maxWidth,
      title: _title(l10n),
      onCancel: _handleCancel,
      onSave: _handleSave,
      saving: _saving,
      body: LibraryEditForm(
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
