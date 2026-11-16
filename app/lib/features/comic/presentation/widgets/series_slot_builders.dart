import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic/presentation/widgets/comic_card_actions.dart';
import 'package:hentai_library/features/comic/presentation/actions/comic_catalog_selection_actions.dart';
import 'package:hentai_library/features/comic/public/ui/comic_cover_content.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/features/comic/presentation/widgets/comic_cover_renderer.dart';
import 'package:hentai_library/shared/ui/slots/series_slots.dart';

/// comic 侧的系列 UI 槽位默认实现（bootstrap 通过 shared/di token 注入）。
Widget buildSeriesCoverSlot(SeriesCoverSlotArgs args) {
  final String? comicId = args.fallbackComicId;
  if (comicId == null) {
    return const SizedBox.shrink();
  }
  return ComicCoverContent(
    comicId: comicId,
    priority: _priorityOf(args.priority),
    gridIndex: args.gridIndex,
    coverViewportScope: args.coverViewportScope,
    attachViewportSensor: args.attachViewportSensor,
    enableHero: args.enableHero,
    paintVariant: args.detail
        ? ComicCoverPaintVariant.detail
        : ComicCoverPaintVariant.card,
  );
}

Widget buildSeriesMemberCoverSlot(SeriesMemberCoverSlotArgs args) {
  return ComicCoverContent(
    comicId: args.comicId,
    gridIndex: args.gridIndex,
    coverViewportScope: args.coverViewportScope,
  );
}

Widget buildSeriesMemberCardSlot(SeriesMemberCardArgs args, Widget child) {
  return ComicCardActions.fromBrowse(
    item: (
      comicId: args.comicId,
      title: args.title,
      pageCount: args.pageCount ?? 0,
      path: args.path,
    ),
    child: child,
  );
}

Future<void> runSeriesMemberSelectionActions(
  BuildContext context,
  WidgetRef ref,
  List<String> ids,
) {
  return openComicMetadataEditorForIds(
    context,
    ref,
    ids,
    exitSelectionOnDone: true,
  );
}

ThumbnailPriority _priorityOf(int index) {
  final List<ThumbnailPriority> values = ThumbnailPriority.values;
  return values[index.clamp(0, values.length - 1)];
}
