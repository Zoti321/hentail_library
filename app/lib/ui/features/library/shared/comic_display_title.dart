import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 同步解析漫画展示标题（含 ID fallback）。
String comicDisplayTitle(WidgetRef ref, String comicId) {
  final Comic? comic = ref.watch(libraryComicByIdProvider(comicId)).value;
  if (comic != null && comic.title.isNotEmpty) {
    return comic.title;
  }
  return comicTitleFallbackForDisplay(comicId);
}
