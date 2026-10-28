import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/layout/md3e_metadata_edit_form_metrics.dart';
import 'package:hentai_library/md3e/pages/md3e_comic_detail_page_preview_data.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_comic_metadata_edit_draft.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_comic_metadata_edit_form.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_metadata_edit_surface.dart';
import 'package:hentai_library/shared/domain/models/value_objects/comic_meta_locks.dart';

export 'package:hentai_library/md3e/patterns/metadata_edit/md3e_comic_metadata_edit_draft.dart';

/// 漫画元数据编辑 Lab 页（Widgetbook / 路由）。
class Md3eComicMetadataEditPage extends StatefulWidget {
  const Md3eComicMetadataEditPage({
    super.key,
    this.initialDraft,
    this.presentation = Md3eMetadataEditPresentation.embedded,
    this.onSaved,
    this.onCancel,
  });

  final Md3eComicMetadataEditDraft? initialDraft;
  final Md3eMetadataEditPresentation presentation;
  final ValueChanged<Md3eComicMetadataEditDraft>? onSaved;
  final VoidCallback? onCancel;

  @override
  State<Md3eComicMetadataEditPage> createState() =>
      _Md3eComicMetadataEditPageState();
}

class _Md3eComicMetadataEditPageState extends State<Md3eComicMetadataEditPage> {
  late Md3eComicMetadataEditDraft _draft = widget.initialDraft ??
      Md3eComicMetadataEditDraft.fromEntry(
        Md3eComicDetailPagePreviewData.sample(),
      );
  String? _titleError;
  bool _saving = false;
  ComicMetaLocks _locks = ComicMetaLocks.unlocked;

  void _onLockChanged({
    bool? title,
    bool? description,
    bool? publishedAt,
    bool? contentRating,
    bool? authors,
    bool? tags,
    bool? languages,
    bool? parodies,
    bool? characters,
  }) {
    setState(
      () => _locks = _locks.copyWith(
        title: title,
        description: description,
        publishedAt: publishedAt,
        contentRating: contentRating,
        authors: authors,
        tags: tags,
        languages: languages,
        parodies: parodies,
        characters: characters,
      ),
    );
  }

  void _handleCancel() {
    widget.onCancel?.call();
    if (widget.onCancel == null && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleSave() async {
    final String? error = _draft.validateTitle();
    if (error != null) {
      setState(() {
        _titleError = error;
      });
      return;
    }
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) {
      return;
    }
    widget.onSaved?.call(_draft);
    setState(() => _saving = false);
    if (widget.onSaved == null && Navigator.canPop(context)) {
      Navigator.of(context).pop(_draft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Md3eMetadataEditSurface(
      presentation: widget.presentation,
      maxWidth: Md3eMetadataEditFormMetrics.comicMaxWidth,
      title: l10n.dialogEditMetadataTitle,
      onCancel: _handleCancel,
      onSave: _handleSave,
      saving: _saving,
      body: Md3eComicMetadataEditForm(
        draft: _draft,
        locks: _locks,
        onLockChanged: _onLockChanged,
        titleError: _titleError,
        onDraftChanged: (Md3eComicMetadataEditDraft value) {
          setState(() {
            _draft = value;
            if (_titleError != null && value.validateTitle() == null) {
              _titleError = null;
            }
          });
        },
      ),
    );
  }
}
