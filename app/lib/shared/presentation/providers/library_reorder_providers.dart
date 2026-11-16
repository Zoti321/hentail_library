/// 共享多选状态与库重排互斥；动作和只读状态分开消费。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/application/contracts/exit_library_reorder_command.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<ExitLibraryReorderCommand> exitLibraryReorderCommandProvider =
    requiredProvider('exitLibraryReorderCommandProvider');

final Provider<bool> libraryReorderActiveStateProvider = requiredProvider(
  'libraryReorderActiveStateProvider',
);
