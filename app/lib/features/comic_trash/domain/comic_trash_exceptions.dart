import 'package:hentai_library/shared/domain/exceptions/domain_exception.dart';

/// Comic trash 限界上下文业务规则违反。
final class ComicTrashException extends DomainException {
  const ComicTrashException._(super.message, {super.code});

  factory ComicTrashException.purgeRequiresTrashedState() {
    return const ComicTrashException._(
      '仅可 purge 已处于 trash 状态的漫画',
      code: 'comic_trash.purge_requires_trashed',
    );
  }
}
