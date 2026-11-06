import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_meta_locks.dart';
import 'package:hentai_library/features/library_browse/public/catalog/for_comic_and_series.dart';

/// 系列元数据编辑 — 全部字段锁 KV 面板。
class SeriesMetadataLocksPane extends StatelessWidget {
  const SeriesMetadataLocksPane({
    super.key,
    required this.locks,
    required this.onLockChanged,
  });

  final SeriesMetaLocks locks;
  final SeriesMetadataLockChanged onLockChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return MetadataFieldLocksKvList(
      entries: <MetadataFieldLockKvEntry>[
        MetadataFieldLockKvEntry(
          label: l10n.formSeriesNameLabel,
          locked: locks.name,
          onChanged: (bool locked) => onLockChanged(name: locked),
        ),
        MetadataFieldLockKvEntry(
          label: l10n.formSeriesSerializationStatusLabel,
          locked: locks.serializationStatus,
          onChanged: (bool locked) =>
              onLockChanged(serializationStatus: locked),
        ),
        MetadataFieldLockKvEntry(
          label: l10n.formSeriesTotalCountLabel,
          locked: locks.totalCount,
          onChanged: (bool locked) => onLockChanged(totalCount: locked),
        ),
      ],
    );
  }
}
