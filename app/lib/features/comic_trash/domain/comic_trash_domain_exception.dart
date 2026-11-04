import 'package:hentai_library/shared/domain/exceptions/domain_rule_violation.dart';

/// Comic trash 限界上下文业务规则违反。
final class ComicTrashDomainException extends DomainRuleViolation {
  const ComicTrashDomainException._(super.message, {super.code});

  factory ComicTrashDomainException.purgeRequiresTrashedState() {
    return const ComicTrashDomainException._(
      '仅可 purge 已处于 trash 状态的漫画',
      code: 'comic_trash.purge_requires_trashed',
    );
  }
}
