import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/author/view_models/author_detail_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/author/views/author_detail/author_detail_layout.dart';
import 'package:hentai_library/features/library_browse/presentation/catalog/views/widgets/detail_status/detail_back_header.dart';
import 'package:hentai_library/features/library_browse/presentation/catalog/views/widgets/detail_status/detail_status_scaffold.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author_detail.dart';
import 'package:hentai_library/shared/ui/theme/app_m3e_theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 作者资料页（独立路由 `/author/:id`）。
class AuthorDetailPage extends ConsumerWidget {
  const AuthorDetailPage({super.key, required this.authorId});

  final int authorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AuthorDetail?> asyncDetail = ref.watch(
      authorDetailProvider(authorId),
    );

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        DetailBackHeader.popOrGoLibrary(context);
      },
      child: M3ETheme(
        data: withAppFontFamily(M3ETheme.of(context)),
        child: ColoredBox(
          color: M3ETheme.of(context).colorScheme.surface,
          child: asyncDetail.when(
            loading: () => const DetailLoadingStatus(),
            error: (Object error, StackTrace stackTrace) =>
                DetailErrorStatus(label: error.toString()),
            data: (AuthorDetail? detail) {
              if (detail == null) {
                return DetailNotFoundStatus(
                  icon: LucideIcons.user,
                  label: context.l10n.comicDetailNotFound,
                );
              }
              return AuthorDetailLayout(
                detail: detail,
                onBack: () => DetailBackHeader.popOrGoLibrary(context),
              );
            },
            skipLoadingOnReload: true,
            skipLoadingOnRefresh: true,
          ),
        ),
      ),
    );
  }
}

/// 按 Author 稳定 id 跳转到作者资料页（有引用时的首选路径）。
void openAuthorDetailById({
  required BuildContext context,
  required int authorId,
}) {
  context.push('/author/$authorId');
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
