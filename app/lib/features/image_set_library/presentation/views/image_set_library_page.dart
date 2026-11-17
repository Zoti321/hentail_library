import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_card.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_cover.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_detail_page.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/application/errors/error_message.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Image set 库浏览：会话内 card/list 双视图与同步 busy 投影（手动同步入口在 Home「更多」）。
class ImageSetLibraryPage extends ConsumerStatefulWidget {
  const ImageSetLibraryPage({
    super.key,
    required this.libraryId,
    required this.displayName,
  });

  final String libraryId;
  final String displayName;

  @override
  ConsumerState<ImageSetLibraryPage> createState() =>
      _ImageSetLibraryPageState();
}

class _ImageSetLibraryPageState extends ConsumerState<ImageSetLibraryPage> {
  // Desktop Scrollbar does not auto-attach to PrimaryScrollController; share
  // an explicit controller with the scrollable body.
  final ScrollController _listScrollController = ScrollController();
  CatalogViewMode _viewMode = CatalogViewMode.grid;

  @override
  void dispose() {
    _listScrollController.dispose();
    super.dispose();
  }

  void _openDetail(ImageSet set) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ImageSetDetailPage(
          libraryId: widget.libraryId,
          imageSet: set,
        ),
      ),
    );
  }

  String _setTitle(AppLocalizations l10n, ImageSet set) =>
      set.isRoot ? l10n.imageSetRootName : set.name;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final double horizontalInset = PageLayoutSpec.of(context).horizontalInset;
    final bool busy = ref.watch(
      librarySyncStateProvider.select((LibrarySyncState s) => s.running),
    );
    final AsyncValue<List<ImageSet>> sets = ref.watch(
      imageSetSetsProvider(widget.libraryId),
    );

    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: theme.spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalInset),
              child: PageTitle(widget.displayName),
            ),
            if (busy) ...<Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: theme.spacing.sm),
                    const LinearProgressIndicator(
                      key: ValueKey<String>('imageSetSyncProgress'),
                    ),
                    SizedBox(height: theme.spacing.xs),
                    Text(
                      l10n.imageSetLibrarySyncing,
                      style: theme.typeScale.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: theme.spacing.md),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalInset),
              child: Align(
                alignment: Alignment.centerRight,
                child: CatalogViewModeButtonGroup(
                  mode: _viewMode,
                  onModeChanged: (CatalogViewMode mode) {
                    setState(() => _viewMode = mode);
                  },
                ),
              ),
            ),
            SizedBox(height: theme.spacing.sm),
            Expanded(
              child: sets.when(
                data: (List<ImageSet> list) => list.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalInset,
                        ),
                        child: _MessageText(l10n.imageSetListEmpty),
                      )
                    : Scrollbar(
                        controller: _listScrollController,
                        thumbVisibility: true,
                        child: _viewMode == CatalogViewMode.list
                            ? ListView.builder(
                                controller: _listScrollController,
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontalInset,
                                ),
                                itemCount: list.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final ImageSet set = list[index];
                                  return ListTile(
                                    key: ValueKey<String>(
                                      'imageSet-${set.imageSetId}',
                                    ),
                                    leading: SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: ImageSetCover(
                                        libraryId: widget.libraryId,
                                        imageSetId: set.imageSetId,
                                      ),
                                    ),
                                    title: Text(
                                      _setTitle(l10n, set),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () => _openDetail(set),
                                  );
                                },
                              )
                            : CustomScrollView(
                                controller: _listScrollController,
                                slivers: <Widget>[
                                  CatalogGridSliver(
                                    itemCount: list.length,
                                    hasSubtitle: false,
                                    itemBuilder:
                                        (
                                          BuildContext context,
                                          int index,
                                          CatalogGridLayout _,
                                        ) {
                                          final ImageSet set = list[index];
                                          return ImageSetCard(
                                            key: ValueKey<String>(
                                              'imageSet-${set.imageSetId}',
                                            ),
                                            libraryId: widget.libraryId,
                                            imageSetId: set.imageSetId,
                                            title: _setTitle(l10n, set),
                                            onTap: () => _openDetail(set),
                                          );
                                        },
                                  ),
                                ],
                              ),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object error, StackTrace _) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalInset),
                  child: _MessageText(
                    l10n.imageSetListLoadFailed(appErrorMessage(error)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageText extends StatelessWidget {
  const _MessageText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.typeScale.bodyMedium.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
