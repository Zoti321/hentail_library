import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/author/view_models/author_detail_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/author/patterns/author_detail/author_detail_comics_section.dart';
import 'package:hentai_library/features/library_browse/presentation/author/views/author_detail/author_detail_header.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author_detail.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 作者详情正文：头部 + 作品区（无外层滚动，供 Lab 页或测试嵌入）。
class AuthorDetailBody extends ConsumerWidget {
  const AuthorDetailBody({super.key, required this.authorId});

  final int authorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<AuthorDetail?> asyncDetail = ref.watch(
      authorDetailProvider(authorId),
    );
    return asyncDetail.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stackTrace) => Text('$error'),
      data: (AuthorDetail? detail) {
        if (detail == null) {
          return Text(l10n.comicDetailNotFound);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AuthorDetailHeader(detail: detail),
            const SizedBox(height: 24),
            AuthorDetailComicsSection(detail: detail),
          ],
        );
      },
    );
  }
}
