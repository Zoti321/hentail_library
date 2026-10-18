import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/author_detail_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/author/show_author_detail.dart';
import 'package:hentai_library/shared/ui/ports/author_detail_port.dart';

/// library_browse 对 [AuthorDetailPort] 的实现（#292）。
///
/// 由 bootstrap 通过 [authorDetailPortProvider] 的 `overrideWith` 注入。
class _AuthorDetailAdapter implements AuthorDetailPort {
  _AuthorDetailAdapter(this._ref);

  final Ref _ref;

  @override
  Future<void> showByName(BuildContext context, String name) async {
    final int? authorId = await _ref
        .read(authorDetailCommandsProvider)
        .idByName(name);
    if (authorId == null || !context.mounted) {
      return;
    }
    await showAuthorDetail(context: context, authorId: authorId);
  }
}

AuthorDetailPort createAuthorDetailPort(Ref ref) => _AuthorDetailAdapter(ref);
