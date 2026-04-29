import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/detail/comic_detail_page/widgets/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ComicDetailPage extends ConsumerWidget {
  const ComicDetailPage({super.key, required this.comicId});
  final String comicId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final tokens = context.tokens;

    final AsyncValue<List<Comic>> rawData = ref.watch(
      libraryRawComicsAsyncProvider,
    );

    return Container(
      color: cs.hentai.winBackground,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.lg + 8,
        vertical: tokens.spacing.lg + 8,
      ),
      child: rawData.when(
        data: (List<Comic> comics) {
          final Comic? found = comics.firstWhereOrNull(
            (Comic c) => c.comicId == comicId,
          );
          if (found == null) {
            return ComicDetailNotFound(comicId: comicId);
          }

          return ComicDetail(comic: found);
        },

        loading: () => const ComicDetailLoading(),
        error: (Object error, StackTrace stackTrace) =>
            ComicDetailError(onRetry: ref.read(libraryRefreshActionProvider)),
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
      ),
    );
  }
}
