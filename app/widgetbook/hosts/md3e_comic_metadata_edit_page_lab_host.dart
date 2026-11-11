import 'package:flutter/material.dart';

import '../preview/md3e_comic_detail_page_preview_data.dart';

import 'package:hentai_library/features/comic/presentation/views/metadata_edit/comic_metadata_edit_page.dart';

import '../preview/md3e_comic_metadata_edit_preview_data.dart';

import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_edit_surface.dart';
import 'package:hentai_library/shared/domain/models/value_objects/comic_meta_locks.dart';

/// Lab / Widgetbook：漫画元数据编辑 + 字段锁 KV preview（切换锁状态，不写 core）。
class ComicMetadataEditPageLabHost extends StatelessWidget {
  const ComicMetadataEditPageLabHost({
    super.key,
    this.initialDraft,
    this.initialLocks,
    this.presentation = MetadataEditPresentation.embedded,
    this.onSaved,
    this.onCancel,
  });

  final ComicMetadataEditDraft? initialDraft;
  final ComicMetaLocks? initialLocks;
  final MetadataEditPresentation presentation;
  final ValueChanged<ComicMetadataEditDraft>? onSaved;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return ComicMetadataEditLayout(
      initialDraft:
          initialDraft ??
          ComicMetadataEditDraft.fromEntry(ComicDetailPagePreviewData.sample()),
      initialLocks:
          initialLocks ?? Md3eComicMetadataEditPreviewData.sampleLocks,
      presentation: presentation,
      onSaved: onSaved,
      onCancel: onCancel,
    );
  }
}
