import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/features/library_browse/presentation/comic_delete_flow.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/comic_detail_series_nav_provider.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_page_comics_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_search_query_parser.dart';
import 'package:hentai_library/features/library_browse/presentation/views/comic_detail_md3e/comic_detail_format.dart';
import 'package:hentai_library/features/library_browse/presentation/views/comic_detail_md3e/comic_detail_md3e_cover.dart';
import 'package:hentai_library/features/library_browse/presentation/views/comic_detail_md3e/comic_detail_md3e_entry.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/detail_status/detail_back_header.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/detail_status/detail_status_scaffold.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/edit_metadata_dialog.dart';
import 'package:hentai_library/md3e/pages/md3e_comic_detail_page.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:hentai_library/shared/di/comic_detail_providers.dart';
import 'package:hentai_library/shared/di/library_command_providers.dart';
import 'package:hentai_library/shared/di/library_management_providers.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/di/read_session_launch_providers.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/custom_toast.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 生产漫画详情页（MD3E）：读取领域数据，经映射层渲染 [Md3eComicDetailPage]。
class ComicDetailMd3ePage extends ConsumerWidget {
  const ComicDetailMd3ePage({super.key, required this.comicId});

  final String comicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      child: M3ETheme(
        data: md3eWithAppFontFamily(M3ETheme.of(context)),
        child: ColoredBox(
          color: M3ETheme.of(context).colorScheme.surface,
          child: comicAsync.when(
            data: (Comic? found) {
              if (found == null) {
                return DetailNotFoundStatus(
                  key: ValueKey<String>(comicId),
                  icon: LucideIcons.bookOpen,
                  label: context.l10n.comicDetailNotFound,
                );
              }
              return _ComicDetailMd3eContent(comic: found);
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
      ),
    );
  }
}

class _ComicDetailMd3eContent extends ConsumerWidget {
  const _ComicDetailMd3eContent({required this.comic});

  final Comic comic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final int? pageCount = ref
        .watch(comicResolvedPageCountProvider(comic.comicId))
        .maybeWhen(data: (int count) => count, orElse: () => comic.pageCount);
    final ComicDetailSeriesNavResult? navResult = ref
        .watch(comicDetailSeriesNavProvider(comic.comicId))
        .value;
    final ComicDetailSeriesNavData? seriesNav =
        navResult is ComicDetailSeriesNavReady ? navResult.data : null;
    final bool isBusy =
        ref.watch(libraryScanRunningStateProvider) ||
        ref.watch(libraryMetadataRefreshRunningStateProvider);

    final Md3eComicDetailEntry entry = comicDetailMd3eEntry(
      comic: comic,
      cover: ComicDetailMd3eCover(comicId: comic.comicId),
      pageCount: pageCount,
      publishedLabel: formatComicPublishedDate(context, comic.publishedAt),
      addedAtLabel: formatComicDetailDateTime(context, comic.createdAt),
      updatedAtLabel: formatComicDetailDateTime(context, comic.lastUpdatedAt),
      seriesTitles: <String>[
        for (final ComicDetailSeriesNavItem item
            in seriesNav?.items ?? const <ComicDetailSeriesNavItem>[])
          item.title,
      ],
      seriesCurrentIndex: seriesNav?.currentIndex ?? 0,
      showSeriesNav: seriesNav != null,
    );

    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Md3eComicDetailPage(
      entry: entry,
      onBack: () => DetailBackHeader.popOrGoLibrary(context),
      onEdit: () => showEditMetadataDialog(context: context, comic: comic),
      moreMenuEntries: <M3EMenuNode>[
        M3EMenuEntry(
          label: l10n.refreshMetadata,
          leading: const Icon(LucideIcons.refreshCw),
          enabled: !isBusy,
          onPressed: () => _refreshMetadata(context, ref),
        ),
        M3EMenuEntry(
          label: l10n.comicDetailShowInExplorer,
          leading: const Icon(LucideIcons.folderOpen),
          onPressed: () => _showInExplorer(context),
        ),
        M3EMenuEntry(
          label: l10n.comicDetailDelete,
          leading: Icon(LucideIcons.trash2, color: scheme.error),
          isDestructive: true,
          onPressed: () => confirmAndTrashComic(
            context,
            ref,
            comic,
            onTrashed: () {
              if (!context.mounted) {
                return;
              }
              if (context.canPop()) {
                context.pop();
              } else {
                goCurrentLibraryBrowseFromContext(context);
              }
            },
          ),
        ),
      ],
      onRead: () => _openReader(ref, incognito: false),
      onReadIncognito: () => _openReader(ref, incognito: true),
      onMetadataChipTap: (String value) {
        final String query = formatLibrarySearchExactMetaQuery(value);
        context.push('/searched?q=${Uri.encodeQueryComponent(query)}');
      },
      onSeriesSelect: (int index) {
        final List<ComicDetailSeriesNavItem>? items = seriesNav?.items;
        if (items == null || index < 0 || index >= items.length) {
          return;
        }
        context.go('/comic/${Uri.encodeComponent(items[index].comicId)}');
      },
    );
  }

  Future<void> _openReader(WidgetRef ref, {required bool incognito}) async {
    await ref
        .read(readSessionLaunchPortProvider)
        .openComic(comicId: comic.comicId, incognito: incognito);
  }

  Future<void> _refreshMetadata(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;
    try {
      await ref
          .read(libraryMetadataRefreshCommandPortProvider)
          .refreshComic(comicId: comic.comicId, title: comic.title);
      if (!context.mounted) {
        return;
      }
      showSuccessToast(context, l10n.refreshMetadataComicSuccess);
    } catch (err) {
      if (context.mounted) {
        showErrorToast(context, err);
      }
    }
  }

  void _showInExplorer(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    showInFileExplorer(comic.path)
        .catchError((Object error, StackTrace stackTrace) {
          if (!context.mounted) {
            return;
          }
          if (error is AppException) {
            showErrorToast(context, error);
            return;
          }
          showErrorToast(
            context,
            AppException(
              l10n.comicDetailShowInExplorerFailed,
              cause: error,
              stackTrace: stackTrace,
            ),
          );
        });
  }
}
