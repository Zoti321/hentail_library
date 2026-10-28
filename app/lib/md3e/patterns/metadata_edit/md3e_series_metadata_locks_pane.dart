import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_metadata_field_locks_kv_list.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_metadata_lock_callbacks.dart';
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
