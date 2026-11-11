import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/models/value_objects/comic_meta_locks.dart';
import 'package:hentai_library/shared/ui/catalog/metadata_edit/metadata_field_locks_kv_list.dart';
import 'package:hentai_library/shared/ui/catalog/metadata_edit/metadata_lock_callbacks.dart';

/// 漫画元数据编辑 — 全部字段锁 KV 面板。
class ComicMetadataLocksPane extends StatelessWidget {
  const ComicMetadataLocksPane({
    super.key,
    required this.locks,
    required this.onLockChanged,
  });

  final ComicMetaLocks locks;
  final ComicMetadataLockChanged onLockChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return MetadataFieldLocksKvList(
      entries: <MetadataFieldLockKvEntry>[
        MetadataFieldLockKvEntry(
          label: l10n.formComicTitleLabel,
          locked: locks.title,
          onChanged: (bool locked) => onLockChanged(title: locked),
        ),
        MetadataFieldLockKvEntry(
          label: l10n.formComicDescriptionLabel,
          locked: locks.description,
          onChanged: (bool locked) => onLockChanged(description: locked),
        ),
        MetadataFieldLockKvEntry(
          label: l10n.formPublishedDateLabel,
          locked: locks.publishedAt,
          onChanged: (bool locked) => onLockChanged(publishedAt: locked),
        ),
        MetadataFieldLockKvEntry(
          label: l10n.formAgeRestrictionLabel,
          locked: locks.contentRating,
          onChanged: (bool locked) => onLockChanged(contentRating: locked),
        ),
        MetadataFieldLockKvEntry(
          label: l10n.formLanguagesLabel,
          locked: locks.languages,
          onChanged: (bool locked) => onLockChanged(languages: locked),
        ),
        MetadataFieldLockKvEntry(
          label: l10n.comicDetailParodies,
          locked: locks.parodies,
          onChanged: (bool locked) => onLockChanged(parodies: locked),
        ),
        MetadataFieldLockKvEntry(
          label: l10n.comicDetailAuthors,
          locked: locks.authors,
          onChanged: (bool locked) => onLockChanged(authors: locked),
        ),
        MetadataFieldLockKvEntry(
          label: l10n.comicDetailCharacters,
          locked: locks.characters,
          onChanged: (bool locked) => onLockChanged(characters: locked),
        ),
        MetadataFieldLockKvEntry(
          label: l10n.comicDetailTags,
          locked: locks.tags,
          onChanged: (bool locked) => onLockChanged(tags: locked),
        ),
      ],
    );
  }
}
