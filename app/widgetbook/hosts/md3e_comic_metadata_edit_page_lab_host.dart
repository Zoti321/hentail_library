import 'package:flutter/material.dart';

import 'md3e_comic_detail_page_preview_data.dart';

import 'package:hentai_library/features/library_browse/presentation/comic/views/metadata_edit_md3e/comic_metadata_edit_page.dart';

import 'md3e_comic_metadata_edit_preview_data.dart';

import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_edit_surface.dart';
import 'package:hentai_library/shared/domain/models/value_objects/comic_meta_locks.dart';

/// Lab / Widgetbook：漫画元数据编辑 + 字段锁 KV preview（切换锁状态，不写 core）。
class Md3eComicMetadataEditPageLabHost extends StatelessWidget {
  const Md3eComicMetadataEditPageLabHost({
    super.key,
    this.initialDraft,
    this.initialLocks,
    this.presentation = Md3eMetadataEditPresentation.embedded,
    this.onSaved,
    this.onCancel,
  });

  final Md3eComicMetadataEditDraft? initialDraft;
  final ComicMetaLocks? initialLocks;
  final Md3eMetadataEditPresentation presentation;
  final ValueChanged<Md3eComicMetadataEditDraft>? onSaved;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Md3eComicMetadataEditPage(
      initialDraft:
          initialDraft ??
          Md3eComicMetadataEditDraft.fromEntry(
            Md3eComicDetailPagePreviewData.sample(),
          ),
      initialLocks:
          initialLocks ?? Md3eComicMetadataEditPreviewData.sampleLocks,
      presentation: presentation,
      onSaved: onSaved,
      onCancel: onCancel,
    );
  }
}
