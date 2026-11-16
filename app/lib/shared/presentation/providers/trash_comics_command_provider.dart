/// Comic 与 trash 的直接协作会构成 public 环；动作经共享命令契约。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/application/contracts/trash_comics_command.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<TrashComicsCommand> trashComicsCommandProvider =
    requiredProvider('trashComicsCommandProvider');
