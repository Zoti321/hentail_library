import 'package:flutter/material.dart';
import 'package:hentai_library/features/library_admin/presentation/views/library/library_edit_page.dart';

import '../preview/md3e_library_edit_preview_data.dart';

import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_edit_surface.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/library_form.dart';

/// Lab / Widgetbook：Library 表单 preview；远程 WebDAV 凭证可编辑内存，不写 secure storage / 无真实连接。
class LibraryEditPageLabHost extends StatefulWidget {
  const LibraryEditPageLabHost({
    super.key,
    this.intent = LibraryEditPageIntent.editLocal,
    this.initialForm,
    this.presentation = MetadataEditPresentation.embedded,
    this.onSaved,
    this.onCancel,
  });

  final LibraryEditPageIntent intent;
  final LibraryForm? initialForm;
  final MetadataEditPresentation presentation;
  final ValueChanged<LibraryForm>? onSaved;
  final VoidCallback? onCancel;

  @override
  State<LibraryEditPageLabHost> createState() =>
      _Md3eLibraryEditPageLabHostState();
}

class _Md3eLibraryEditPageLabHostState
    extends State<LibraryEditPageLabHost> {
  LibraryForm? _previewFormAfterSave;

  LibraryForm _resolveInitialForm() {
    if (widget.initialForm != null) {
      return widget.initialForm!;
    }
    if (_previewFormAfterSave != null) {
      return _previewFormAfterSave!;
    }
    return switch (widget.intent) {
      LibraryEditPageIntent.editLocal =>
        LibraryEditPreviewData.editLocalForm(),
      LibraryEditPageIntent.editRemote =>
        LibraryEditPreviewData.editRemoteForm(),
      LibraryEditPageIntent.createLocal => LibraryForm.createLocal(),
      LibraryEditPageIntent.createRemote => LibraryForm.createRemote(),
    };
  }

  void _handleSaved(LibraryForm form) {
    setState(() => _previewFormAfterSave = form);
    widget.onSaved?.call(form);
  }

  @override
  Widget build(BuildContext context) {
    return LibraryEditPage(
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
