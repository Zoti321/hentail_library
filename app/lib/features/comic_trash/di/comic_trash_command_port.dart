import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic_trash/presentation/view_models/comic_trash_actions.dart';
import 'package:hentai_library/shared/domain/ports/comic_trash_command_port.dart';

class _ComicTrashCommandAdapter implements ComicTrashCommandPort {
  _ComicTrashCommandAdapter(this._ref);

  final Ref _ref;

  @override
  Future<void> trash(List<String> comicIds) =>
      _ref.read(comicTrashActionsProvider.notifier).trash(comicIds);
}

ComicTrashCommandPort createComicTrashCommandPort(Ref ref) =>
    _ComicTrashCommandAdapter(ref);
