import 'dart:typed_data';

import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/src/rust/api/metadata_backup.dart';

/// Comic 用户元数据备份 FRB 薄封装。
class MetadataBackupFrbAdapter {
  const MetadataBackupFrbAdapter();

  Uint8List export({required ExportComicMetadataOptionsDto options}) {
    return guardFrbSync(
      () => exportComicMetadataFrb(options: options),
      fallbackMessage: '导出元数据失败',
    );
  }

  MetadataBackupManifestDto peek({required Uint8List bytes}) {
    return guardFrbSync(
      () => peekMetadataBackupManifestFrb(bytes: bytes),
      fallbackMessage: '读取元数据备份摘要失败',
    );
  }

  ImportComicMetadataResultDto import({required Uint8List bytes}) {
    return guardFrbSync(
      () => importComicMetadataFrb(bytes: bytes),
      fallbackMessage: '导入元数据失败',
    );
  }
}
