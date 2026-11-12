/// 共享壳只依赖导出 UI 动作；metadata_backup owner 实现。
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<Future<void> Function(BuildContext context, String libraryId)>
libraryMetadataExportActionProvider = requiredProvider(
  'libraryMetadataExportActionProvider',
);
