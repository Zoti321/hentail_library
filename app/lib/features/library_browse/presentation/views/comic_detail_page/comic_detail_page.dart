import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/features/library_browse/presentation/views/comic_detail_page/widgets/widgets.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/detail_status/detail_status_scaffold.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_page_comics_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ComicDetailPage extends ConsumerWidget {
  const ComicDetailPage({super.key, required this.comicId});

  final String comicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncValue<Comic?> comicAsync = ref.watch(
      libraryComicDetailProvider(comicId),
    );

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        DetailBackHeader.popOrGoLibrary(context);
      },
      child: ColoredBox(
        color: cs.surface,
        child: comicAsync.when(
          data: (Comic? found) {
            if (found == null) {
              return DetailNotFoundStatus(
                key: ValueKey<String>(comicId),
                icon: LucideIcons.bookOpen,
                label: context.l10n.comicDetailNotFound,
              );
            }
            return ComicDetail(comic: found);
          },
          loading: () => const DetailLoadingStatus(),
          error: (Object error, StackTrace stackTrace) => DetailErrorStatus(
            label: context.l10n.comicDetailLoadFailedRetry,
            onRetry: ref.read(libraryRefreshActionProvider),
          ),
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
        ),
      ),
    );
  }
}
