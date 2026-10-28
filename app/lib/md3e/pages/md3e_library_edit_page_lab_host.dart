import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/pages/md3e_library_edit_page.dart';
import 'package:hentai_library/md3e/patterns/library_admin/md3e_library_edit_preview_data.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_metadata_edit_surface.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/library_form.dart';

/// Lab / Widgetbook：Library 表单 preview；远程 WebDAV 凭证可编辑内存，不写 secure storage / 无真实连接。
class Md3eLibraryEditPageLabHost extends StatefulWidget {
  const Md3eLibraryEditPageLabHost({
    super.key,
    this.intent = Md3eLibraryEditPageIntent.editLocal,
    this.initialForm,
    this.presentation = Md3eMetadataEditPresentation.embedded,
    this.onSaved,
    this.onCancel,
  });

  final Md3eLibraryEditPageIntent intent;
  final LibraryForm? initialForm;
  final Md3eMetadataEditPresentation presentation;
  final ValueChanged<LibraryForm>? onSaved;
  final VoidCallback? onCancel;

  @override
  State<Md3eLibraryEditPageLabHost> createState() =>
      _Md3eLibraryEditPageLabHostState();
}

class _Md3eLibraryEditPageLabHostState extends State<Md3eLibraryEditPageLabHost> {
  LibraryForm? _previewFormAfterSave;

  LibraryForm _resolveInitialForm() {
    if (widget.initialForm != null) {
      return widget.initialForm!;
    }
    if (_previewFormAfterSave != null) {
      return _previewFormAfterSave!;
    }
    return switch (widget.intent) {
      Md3eLibraryEditPageIntent.editLocal =>
        Md3eLibraryEditPreviewData.editLocalForm(),
      Md3eLibraryEditPageIntent.editRemote =>
        Md3eLibraryEditPreviewData.editRemoteForm(),
      Md3eLibraryEditPageIntent.createLocal => LibraryForm.createLocal(),
      Md3eLibraryEditPageIntent.createRemote => LibraryForm.createRemote(),
    };
  }

  void _handleSaved(LibraryForm form) {
    setState(() => _previewFormAfterSave = form);
    widget.onSaved?.call(form);
  }

  @override
  Widget build(BuildContext context) {
    return Md3eLibraryEditPage(
      key: ValueKey<Object?>(
        widget.initialForm ?? _previewFormAfterSave ?? widget.intent,
      ),
      intent: widget.intent,
      initialForm: _resolveInitialForm(),
      presentation: widget.presentation,
      onSaved: _handleSaved,
      onCancel: widget.onCancel,
    );
  }
}
