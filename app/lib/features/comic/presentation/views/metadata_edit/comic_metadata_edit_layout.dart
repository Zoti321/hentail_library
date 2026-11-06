import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/layout/metadata_edit_form_metrics.dart';
import 'package:hentai_library/shared/ui/motion/motion.dart';
import 'package:hentai_library/features/comic/presentation/patterns/metadata_edit/comic_metadata_edit_draft.dart';
import 'package:hentai_library/features/comic/presentation/patterns/metadata_edit/comic_metadata_smart_facet_scope.dart';
import 'package:hentai_library/features/comic/presentation/patterns/metadata_edit/comic_metadata_edit_form.dart';
import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_edit_surface.dart';
import 'package:hentai_library/shared/domain/models/value_objects/comic_meta_locks.dart';

export 'package:hentai_library/features/comic/presentation/patterns/metadata_edit/comic_metadata_edit_draft.dart';

/// 漫画元数据编辑 Lab 页（Widgetbook / 路由）。
class ComicMetadataEditLayout extends StatefulWidget {
  const ComicMetadataEditLayout({
    super.key,
    required this.initialDraft,
    this.initialLocks,
    this.presentation = MetadataEditPresentation.embedded,
    this.onSaved,
    this.onCancel,
  });

  final ComicMetadataEditDraft initialDraft;
  final ComicMetaLocks? initialLocks;
  final MetadataEditPresentation presentation;
  final ValueChanged<ComicMetadataEditDraft>? onSaved;
  final VoidCallback? onCancel;

  @override
  State<ComicMetadataEditLayout> createState() =>
      _ComicMetadataEditPageState();
}

class _ComicMetadataEditPageState extends State<ComicMetadataEditLayout> {
  late ComicMetadataEditDraft _draft = widget.initialDraft;
  String? _titleError;
  bool _saving = false;
  ComicMetaLocks _locks = ComicMetaLocks.unlocked;

  @override
  void initState() {
    super.initState();
    _locks = widget.initialLocks ?? ComicMetaLocks.unlocked;
  }

  @override
  void didUpdateWidget(covariant ComicMetadataEditLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLocks != null &&
        widget.initialLocks != oldWidget.initialLocks) {
      _locks = widget.initialLocks!;
    }
  }

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

  Future<void> saveAndPop() => _handleSave();

  Future<void> _handleSave() async {
    final String? error = _draft.validateTitle();
    if (error != null) {
      setState(() {
        _titleError = error;
      });
      return;
    }
    setState(() => _saving = true);
    await Future<void>.delayed(LabMotion.labSimulatedSaveDuration);
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

    return MetadataEditSurface(
      presentation: widget.presentation,
      maxWidth: MetadataEditFormMetrics.comicMaxWidth,
      title: l10n.dialogEditMetadataTitle,
      onCancel: _handleCancel,
      onSave: _handleSave,
      saving: _saving,
      body: ComicMetadataEditForm(
        draft: _draft,
        locks: _locks,
        onLockChanged: _onLockChanged,
        titleError: _titleError,
        smartFacetScope: labComicMetadataSmartFacetScope(title: _draft.title),
        onDraftChanged: (ComicMetadataEditDraft value) {
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
