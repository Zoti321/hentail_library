import 'package:file_picker/file_picker.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/features/library_admin/data/local_library_root_access.dart';
import 'package:hentai_library/features/library_admin/presentation/views/library/library_confirm_dialog.dart';
import 'package:hentai_library/features/library_admin/presentation/widgets/library_edit_form_metrics.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/adaptive_form_dialog.dart';
import 'package:hentai_library/features/library_admin/presentation/patterns/library_edit_form.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/features/library_admin/domain/resource_format_category.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/library_form.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:path/path.dart' as p;

enum LibraryFormMode { createLocal, createRemote, edit }

/// 打开 Library 创建 / 编辑：[M3EDialog.showAdaptive]（宽 < 840 全屏，否则基础弹窗）。
Future<void> showLibraryFormDialog({
  required BuildContext context,
  required LibraryFormMode mode,
  LocalLibrary? library,
}) {
  assert(
    mode != LibraryFormMode.edit || library != null,
    'library is required for LibraryFormMode.edit',
  );
  final AppLocalizations l10n = context.l10n;
  final String title = _titleFor(l10n, mode);
  final bool isCreate = mode != LibraryFormMode.edit;
  final GlobalKey<_LibraryFormState> formKey = GlobalKey<_LibraryFormState>();
  // 侧栏等非 MD3E 页面发起时，路由内同样需要 M3E 主题与应用字体。
  final M3EThemeData m3e = withAppFontFamily(M3ETheme.of(context));

  return showAdaptiveFormDialog<void>(
    context,
    title: title,
    form: M3ETheme(
      data: m3e,
      child: _LibraryFormFields(
        key: formKey,
        mode: mode,
        library: library,
        formOnly: true,
      ),
    ),
    confirmLabel: isCreate ? l10n.commonAdd : l10n.commonSaveChanges,
    dismissLabel: l10n.commonCancel,
    onConfirm: () => formKey.currentState?._save(),
    basicMaxWidth: LibraryEditFormMetrics.maxWidth,
  );
}

String _titleFor(AppLocalizations l10n, LibraryFormMode mode) {
  return switch (mode) {
    LibraryFormMode.createLocal => l10n.dialogCreateLocalLibraryTitle,
    LibraryFormMode.createRemote => l10n.dialogCreateRemoteLibraryTitle,
    LibraryFormMode.edit => l10n.dialogEditLibraryTitle,
  };
}

class _LibraryFormFields extends ConsumerStatefulWidget {
  const _LibraryFormFields({
    super.key,
    required this.mode,
    required this.library,
    required this.formOnly,
  });

  final LibraryFormMode mode;
  final LocalLibrary? library;
  final bool formOnly;

  @override
  ConsumerState<_LibraryFormFields> createState() => _LibraryFormState();
}

class _LibraryFormState extends ConsumerState<_LibraryFormFields> {
  late LibraryForm _form = switch (widget.mode) {
    LibraryFormMode.createLocal => LibraryForm.createLocal(),
    LibraryFormMode.createRemote => LibraryForm.createRemote(),
    LibraryFormMode.edit => LibraryForm.fromLibrary(widget.library!),
  };
  LibraryFormValidation? _validation;
  bool _saving = false;

  bool get _isCreate => widget.mode != LibraryFormMode.edit;
  bool get _isRemote => _form.isRemote;

  Future<bool> _confirmRootChangeIfNeeded() async {
    final LocalLibrary? original = widget.library;
    if (original == null) {
      return true;
    }
    if (_form.rootPath.trim() == original.rootPath.trim()) {
      return true;
    }
    final AppLocalizations l10n = context.l10n;
    return showLibraryConfirmDialog(
      context,
      title: l10n.formLibraryRootChangeConfirmTitle,
      content: Text(l10n.formLibraryRootChangeConfirmBody),
      confirmLabel: l10n.commonSave,
    );
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    final AppLocalizations l10n = context.l10n;
    final LibraryFormValidation validation = _form.validate(
      isCreate: _isCreate,
    );
    if (!validation.isValid) {
      setState(() => _validation = validation);
      return;
    }

    if (requiresDisableAllResourceFormatCategoriesConfirm(
      _form.enabledResourceFormatCategories,
    )) {
      final bool confirmed = await showLibraryConfirmDialog(
        context,
        title: l10n.settingsDisableAllFormatsConfirmTitle,
        content: Text(l10n.settingsDisableAllFormatsConfirmContent),
        confirmLabel: l10n.commonSave,
      );
      if (!confirmed || !mounted) {
        return;
      }
    }

    if (!await _confirmRootChangeIfNeeded() || !mounted) {
      return;
    }

    if (!_isRemote && _isCreate) {
      await ensureLocalFilesystemAccess();
      if (!mounted) {
        return;
      }
      if (!await isLocalLibraryRootReadable(_form.rootPath)) {
        if (!mounted) {
          return;
        }
        setState(() {
          _validation = LibraryFormValidation(
            rootError: l10n.formLibraryRootUnreadable,
          );
        });
        return;
      }
    }

    setState(() {
      _validation = null;
      _saving = true;
    });
    try {
      final LibraryFormApplyResult result = await ref
          .read(librariesPortProvider)
          .submitLibraryForm(
            _form,
            original: _isCreate ? null : widget.library!,
          );
      if (!mounted) {
        return;
      }
      switch (result) {
        case LibraryFormApplyInvalid(:final LibraryFormValidation validation):
          setState(() => _validation = validation);
        case LibraryFormApplySucceeded():
          final String toast = switch (widget.mode) {
            LibraryFormMode.createLocal => l10n.libraryLocalAddedToast,
            LibraryFormMode.createRemote => l10n.remoteLibraryAddedToast,
            LibraryFormMode.edit => l10n.commonSavedToast,
          };
          showSuccessSnackbar(context, toast);
          Navigator.of(context).pop();
      }
    } catch (error, stackTrace) {
      logError(AppLog.ui('libraryForm'), '提交库表单失败', error, stackTrace);
      if (mounted) {
        showErrorSnackbar(context, l10n.commonSaveFailedToast);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _browseLocalRoot() async {
    await ensureLocalFilesystemAccess();
    if (!mounted) {
      return;
    }
    final String? directoryPath = await FilePicker.getDirectoryPath();
    if (directoryPath == null || directoryPath.isEmpty || !mounted) {
      return;
    }
    if (!await isLocalLibraryRootReadable(directoryPath)) {
      if (!mounted) {
        return;
      }
      setState(() {
        _validation = LibraryFormValidation(
          rootError: context.l10n.formLibraryRootUnreadable,
        );
      });
      return;
    }
    setState(() {
      final bool nameWasEmpty = _form.name.trim().isEmpty;
      _form = _form.copyWith(rootPath: directoryPath);
      if (nameWasEmpty) {
        _form = _form.copyWith(name: p.basename(directoryPath));
      }
      if (_validation?.rootError != null || _validation?.nameError != null) {
        _validation = null;
      }
    });
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    final Widget form = LibraryEditForm(
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
      onBrowseRoot: _isRemote ? null : _browseLocalRoot,
    );

    if (widget.formOnly) {
      return SingleChildScrollView(child: form);
    }

    final double horizontalInset = PageLayoutSpec.of(context).horizontalInset;

    return M3EDialog(
      title: _titleFor(l10n, widget.mode),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: LibraryEditFormMetrics.maxWidth,
          maxHeight: MediaQuery.sizeOf(context).height * 0.55,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalInset * 0.25),
          child: form,
        ),
      ),
      bottomDivider: true,
      actions: <Widget>[
        M3EButton(
          onPressed: _saving ? null : _handleCancel,
          style: M3EButtonStyle.text,
          label: Text(l10n.commonCancel),
        ),
        M3EButton(
          onPressed: _saving ? null : _save,
          style: M3EButtonStyle.filled,
          label: _saving
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: M3ETheme.of(context).colorScheme.onPrimary,
                  ),
                )
              : Text(_isCreate ? l10n.commonAdd : l10n.commonSaveChanges),
        ),
      ],
    );
  }
}
