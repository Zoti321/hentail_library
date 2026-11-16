import 'package:hentai_library/shared/presentation/providers/trash_comics_command_provider.dart';
import 'package:hentai_library/composition/modules/comic_trash/trash_comics_command.dart';
import 'package:riverpod/misc.dart' show Override;

/// comic_trash owner 命令 注入（#435）。
///
/// app_settings 的阅读偏好 / 主题偏好已按 ADR-0046 归位到
/// `app_settings/public/di`，不再经 `shared/presentation/providers` 转发。
List<Override> appSettingsAndTrashSharedStateOverrides() => <Override>[
  trashComicsCommandProvider.overrideWith(createTrashComicsCommand),
];
