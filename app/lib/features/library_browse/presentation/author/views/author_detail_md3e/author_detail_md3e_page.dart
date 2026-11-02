import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/features/library_browse/presentation/author/view_models/author_detail_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/author/views/author_detail_md3e/author_detail_md3e_body.dart';
import 'package:hentai_library/features/library_browse/presentation/catalog/views/widgets/detail_status/detail_back_header.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';

/// 作者资料页（独立路由 `/author/:id`）。
class AuthorDetailMd3ePage extends StatelessWidget {
  const AuthorDetailMd3ePage({super.key, required this.authorId});

  final int authorId;

  @override
  Widget build(BuildContext context) {
    final Md3ePageLayoutSpec layout = Md3ePageLayoutSpec.of(context);
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        DetailBackHeader.popOrGoLibrary(context);
      },
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const DetailBackHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  layout.horizontalInset,
                  layout.headerToBodyGap,
                  layout.horizontalInset,
                  layout.bodyBottomInset,
                ),
                child: AuthorDetailMd3eBody(authorId: authorId),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 按作者名跳转到作者资料页；名称不存在时静默忽略。
Future<void> openAuthorDetailByName({
  required BuildContext context,
  required WidgetRef ref,
  required String name,
}) async {
  final int? authorId = await ref
      .read(authorDetailCommandsProvider)
      .idByName(name);
  if (authorId == null || !context.mounted) {
    return;
  }
  context.push('/author/$authorId');
}
