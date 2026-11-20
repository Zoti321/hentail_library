import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_detail_page.dart';
import 'package:hentai_library/shared/ui/catalog/detail/detail_not_found_status.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/navigation/app_navigator_context.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// go_router 图集详情落地页：按 [imageSetId] 解析目录项后渲染 [ImageSetDetailPage]。
class ImageSetDetailRoutePage extends ConsumerWidget {
  const ImageSetDetailRoutePage({
    super.key,
    required this.libraryId,
    required this.imageSetId,
  });

  final String libraryId;
  final String imageSetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ImageSet?> imageSetAsync = ref.watch(
      imageSetForRouteProvider((
        libraryId: libraryId,
        imageSetId: imageSetId,
      )),
    );
    return PopScope(
      canPop: appNavigatorOf(context).canPop(),
      child: imageSetAsync.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (Object error, StackTrace stackTrace) => Scaffold(
          body: Center(child: Text(error.toString())),
        ),
        data: (ImageSet? imageSet) => imageSet == null
            ? DetailNotFoundStatus(
                key: ValueKey<String>(imageSetId),
                icon: LucideIcons.images,
                label: context.l10n.comicDetailNotFound,
              )
            : ImageSetDetailPage(libraryId: libraryId, imageSet: imageSet),
      ),
    );
  }
}