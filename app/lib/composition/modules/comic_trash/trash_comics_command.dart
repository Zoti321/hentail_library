import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic_trash/presentation/view_models/comic_trash_actions.dart';
import 'package:hentai_library/shared/application/contracts/trash_comics_command.dart';

TrashComicsCommand createTrashComicsCommand(Ref ref) =>
    (ids) => ref.read(comicTrashActionsProvider.notifier).trash(ids);
