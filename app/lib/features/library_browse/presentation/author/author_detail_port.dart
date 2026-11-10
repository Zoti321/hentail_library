import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/features/library_browse/presentation/author/view_models/author_detail_notifier.dart';
import 'package:hentai_library/features/library_browse/public.dart';

/// library_browse 对 [AuthorDetailPort] 的实现（#292）。
///
/// 由 bootstrap 通过 [authorDetailPortProvider] 的 `overrideWith` 注入。
class _AuthorDetailAdapter implements AuthorDetailPort {
  _AuthorDetailAdapter(this._ref);

  final Ref _ref;

  @override
  Future<void> showById(BuildContext context, int authorId) async {
    if (!context.mounted) {
      return;
    }
    GoRouter.of(context).push('/author/$authorId');
  }

  @override
  Future<void> showByName(BuildContext context, String name) async {
    final int? authorId = await _ref
        .read(authorDetailCommandsProvider)
        .idByName(name);
    if (authorId == null || !context.mounted) {
      return;
    }
    GoRouter.of(context).push('/author/$authorId');
  }
}

AuthorDetailPort createAuthorDetailPort(Ref ref) => _AuthorDetailAdapter(ref);
