import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_entry.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_detail_header.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_image_tile.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_row_grid_sliver.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/application/errors/error_message.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Image set 详情：顶栏（标题/张数）+ 无标题按行顶对齐图流。
class ImageSetDetailPage extends ConsumerWidget {
  const ImageSetDetailPage({
    super.key,
    required this.libraryId,
    required this.imageSet,
  });

  final String libraryId;
  final ImageSet imageSet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final double horizontalInset = PageLayoutSpec.of(context).horizontalInset;
    final ImageSetImagesKey key = (
      libraryId: libraryId,
      imageSetId: imageSet.imageSetId,
    );
    final AsyncValue<List<ImageSetImage>> images = ref.watch(
      imageSetImagesProvider(key),
    );
    final String title = imageSet.isRoot
        ? l10n.imageSetRootName
        : imageSet.name;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalInset,
                vertical: theme.spacing.sm,
              ),
              child: DetailHeaderBackButton(
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: images.when(
                data: (List<ImageSetImage> list) => CustomScrollView(
                  slivers: <Widget>[
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalInset,
                        0,
                        horizontalInset,
                        theme.spacing.md,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: ImageSetDetailHeader(
                          libraryId: libraryId,
                          imageSetId: imageSet.imageSetId,
                          title: title,
                          imageCount: list.length,
                        ),
                      ),
                    ),
                    if (list.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: Text(l10n.imageSetDetailEmpty)),
                      )
                    else
                      ImageSetRowGridSliver(
                        itemCount: list.length,
                        itemBuilder: (BuildContext context, int index) {
                          final ImageSetImage image = list[index];
                          return ImageSetImageTile(
                            key: ValueKey<String>(image.imageSetImageId),
                            libraryId: libraryId,
                            image: image,
                            onTap: () =>
                                ref.read(imageSetReaderEntryCommandProvider)(
                                  ImageSetReaderEntry(
                                    libraryId: libraryId,
                                    imageSetId: imageSet.imageSetId,
                                    imageSetImageId: image.imageSetImageId,
                                    index: index,
                                  ),
                                ),
                          );
                        },
                      ),
                    // Bottom breathing room.
                    SliverToBoxAdapter(
                      child: SizedBox(height: theme.spacing.lg),
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object error, StackTrace _) =>
                    Center(child: Text(appErrorMessage(error))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
