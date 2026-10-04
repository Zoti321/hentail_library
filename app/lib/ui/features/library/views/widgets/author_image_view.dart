import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hentai_library/core/image/image_decode_cache_size.dart';
import 'package:hentai_library/domain/models/entity/comic/author_detail.dart';
import 'package:hentai_library/ui/core/interaction/app_motion.dart';
import 'package:hentai_library/ui/core/widgets/element/image/comic_cover_content.dart';
import 'package:hentai_library/ui/features/library/view_models/author_detail_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Author image：底层先显示库缩略图，高清图就绪后淡入覆盖；高清不可用时停留在缩略图。
class AuthorImageView extends ConsumerWidget {
  const AuthorImageView({
    super.key,
    required this.authorId,
    required this.slot,
    required this.comicId,
    this.alignment = Alignment.center,
  });

  static const Key hdImageKey = ValueKey<String>('author-image-hd');

  final int authorId;
  final AuthorImageSlot slot;

  /// 过渡用缩略图所属 Comic。
  final String comicId;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Uint8List? hd = ref
        .watch(authorImageProvider((authorId: authorId, slot: slot)))
        .value;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final ImageDecodeCacheSize cacheSize = decodeCacheSizeForContext(
          context,
          logicalWidth: constraints.maxWidth,
          logicalHeight: constraints.maxHeight,
        );
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ComicCoverContent(
              comicId: comicId,
              fit: BoxFit.cover,
              alignment: alignment,
            ),
            if (hd != null && hd.isNotEmpty)
              Image.memory(
                hd,
                key: hdImageKey,
                fit: BoxFit.cover,
                alignment: alignment,
                cacheWidth: cacheSize.cacheWidth,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                frameBuilder:
                    (
                      BuildContext context,
                      Widget child,
                      int? frame,
                      bool wasSynchronouslyLoaded,
                    ) {
                      if (wasSynchronouslyLoaded) {
                        return child;
                      }
                      return AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: motionDurationOf(
                          context,
                          const Duration(milliseconds: 200),
                        ),
                        curve: Curves.easeOutCubic,
                        child: child,
                      );
                    },
                errorBuilder:
                    (BuildContext context, Object error, StackTrace? stack) =>
                        const SizedBox.shrink(),
              ),
          ],
        );
      },
    );
  }
}
