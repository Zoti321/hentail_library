import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/ports/comic_trash_command_port.dart';

final Provider<ComicTrashCommandPort> comicTrashCommandPortProvider =
    Provider<ComicTrashCommandPort>(
      (Ref ref) => throw UnimplementedError(
        'comicTrashCommandPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );
