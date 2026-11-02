import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/catalog/patterns/metadata_edit/metadata_field_locks_kv_list.dart';
import 'package:hentai_library/features/library_browse/presentation/catalog/patterns/metadata_edit/metadata_lock_callbacks.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_meta_locks.dart';

/// 系列元数据编辑 — 全部字段锁 KV 面板。
class Md3eSeriesMetadataLocksPane extends StatelessWidget {
  const Md3eSeriesMetadataLocksPane({
    super.key,
    required this.locks,
    required this.onLockChanged,
  });

  final SeriesMetaLocks locks;
  final Md3eSeriesMetadataLockChanged onLockChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Md3eMetadataFieldLocksKvList(
      entries: <Md3eMetadataFieldLockKvEntry>[
        Md3eMetadataFieldLockKvEntry(
          label: l10n.formSeriesNameLabel,
          locked: locks.name,
          onChanged: (bool locked) => onLockChanged(name: locked),
        ),
        Md3eMetadataFieldLockKvEntry(
          label: l10n.formSeriesSerializationStatusLabel,
          locked: locks.serializationStatus,
          onChanged: (bool locked) =>
              onLockChanged(serializationStatus: locked),
        ),
        Md3eMetadataFieldLockKvEntry(
          label: l10n.formSeriesTotalCountLabel,
          locked: locks.totalCount,
          onChanged: (bool locked) => onLockChanged(totalCount: locked),
        ),
      ],
    );
  }
}
