import 'package:flutter/material.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/ui/features/library/views/comic_detail_page/widgets/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ComicDetailPage extends ConsumerWidget {
  const ComicDetailPage({super.key, required this.comicId});

  final String comicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncValue<Comic?> comicAsync = ref.watch(
      libraryComicDetailProvider(comicId),
    );

    return ColoredBox(
      color: cs.surface,
      child: comicAsync.when(
        data: (Comic? found) {
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
