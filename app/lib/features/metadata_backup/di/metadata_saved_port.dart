import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/metadata_backup/presentation/view_models/metadata_auto_backup_coordinator_notifier.dart';
import 'package:hentai_library/shared/domain/ports/metadata_saved_port.dart';

class _MetadataSavedAdapter implements MetadataSavedPort {
  _MetadataSavedAdapter(this._ref);

  final Ref _ref;

  @override
  void notifyMetadataSaved() => _ref
      .read(metadataAutoBackupCoordinatorProvider.notifier)
      .notifyMetadataSaved();
}

/// 适配器工厂：由 bootstrap 通过 `shared/di` 的端口 Provider `overrideWith` 注入（#267）。
MetadataSavedPort createMetadataSavedPort(Ref ref) =>
    _MetadataSavedAdapter(ref);
