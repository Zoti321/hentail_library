import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/models/value_objects/comic_meta_locks.dart';
import 'package:hentai_library/features/library_browse/public/catalog/for_comic_and_series.dart';

/// 漫画元数据编辑 — 全部字段锁 KV 面板。
class Md3eComicMetadataLocksPane extends StatelessWidget {
  const Md3eComicMetadataLocksPane({
    super.key,
    required this.locks,
    required this.onLockChanged,
  });

  final ComicMetaLocks locks;
  final Md3eComicMetadataLockChanged onLockChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Md3eMetadataFieldLocksKvList(
      entries: <Md3eMetadataFieldLockKvEntry>[
        Md3eMetadataFieldLockKvEntry(
          label: l10n.formComicTitleLabel,
          locked: locks.title,
          onChanged: (bool locked) => onLockChanged(title: locked),
        ),
        Md3eMetadataFieldLockKvEntry(
          label: l10n.formComicDescriptionLabel,
          locked: locks.description,
          onChanged: (bool locked) => onLockChanged(description: locked),
        ),
        Md3eMetadataFieldLockKvEntry(
          label: l10n.formPublishedDateLabel,
          locked: locks.publishedAt,
          onChanged: (bool locked) => onLockChanged(publishedAt: locked),
        ),
        Md3eMetadataFieldLockKvEntry(
          label: l10n.formAgeRestrictionLabel,
          locked: locks.contentRating,
          onChanged: (bool locked) => onLockChanged(contentRating: locked),
        ),
        Md3eMetadataFieldLockKvEntry(
          label: l10n.formLanguagesLabel,
          locked: locks.languages,
          onChanged: (bool locked) => onLockChanged(languages: locked),
        ),
        Md3eMetadataFieldLockKvEntry(
          label: l10n.comicDetailParodies,
          locked: locks.parodies,
          onChanged: (bool locked) => onLockChanged(parodies: locked),
        ),
        Md3eMetadataFieldLockKvEntry(
          label: l10n.comicDetailAuthors,
          locked: locks.authors,
          onChanged: (bool locked) => onLockChanged(authors: locked),
        ),
        Md3eMetadataFieldLockKvEntry(
          label: l10n.comicDetailCharacters,
          locked: locks.characters,
          onChanged: (bool locked) => onLockChanged(characters: locked),
        ),
        Md3eMetadataFieldLockKvEntry(
          label: l10n.comicDetailTags,
          locked: locks.tags,
          onChanged: (bool locked) => onLockChanged(tags: locked),
        ),
      ],
    );
  }
}
