import 'package:flutter/material.dart';
import 'package:hentai_library/shared/domain/models/value_objects/author_ref.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/features/comic/presentation/comic_delete_flow.dart';
import 'package:hentai_library/features/comic/presentation/view_models/comic_detail_series_nav_provider.dart';
import 'package:hentai_library/features/comic/presentation/views/comic_detail/comic_detail_format.dart';
import 'package:hentai_library/features/comic/presentation/views/comic_detail/comic_detail_cover.dart';
import 'package:hentai_library/features/comic/presentation/views/comic_detail/comic_detail_entry.dart';
import 'package:hentai_library/features/comic/presentation/views/comic_detail/comic_detail_layout.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/library_admin/public/providers/library_admin_state_providers.dart';
import 'package:hentai_library/shared/presentation/providers/app_navigator_provider.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/features/comic/presentation/providers/comic_detail_providers.dart';
import 'package:hentai_library/features/comic/presentation/navigation/comic_detail_back_location.dart';
import 'package:hentai_library/features/comic/presentation/actions/comic_metadata_edit_presenters.dart';
import 'package:hentai_library/shared/presentation/providers/author_detail_providers.dart';
import 'package:hentai_library/shared/ui/catalog/detail/detail_back_header.dart';
import 'package:hentai_library/shared/ui/catalog/detail/detail_status_scaffold.dart';
import 'package:hentai_library/shared/ui/navigation/app_navigator_context.dart';
import 'package:hentai_library/shared/ui/navigation/library_browse_navigation.dart';

export 'package:hentai_library/features/comic/presentation/views/comic_detail/comic_detail_layout.dart';
export 'package:hentai_library/features/comic/presentation/views/comic_detail/comic_detail_view_object.dart';

/// 生产漫画详情页（MD3E）：读取领域数据，经映射层渲染 [ComicDetailLayout]。
class ComicDetailPage extends ConsumerWidget {
  const ComicDetailPage({super.key, required this.comicId});

  final String comicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Comic?> comicAsync = ref.watch(
      comicDetailProvider(comicId),
    );

    return PopScope(
      canPop: appNavigatorOf(context).canPop(),
      onPopInvokedWithResult: (bool didPop, Object? result) =>
          _handlePopInvoked(context, didPop),
      child: M3ETheme(
        data: withAppFontFamily(M3ETheme.of(context)),
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
              return _ComicDetailContent(comic: found);
            },
            loading: () => const DetailLoadingStatus(),
            error: (Object error, StackTrace stackTrace) => DetailErrorStatus(
              label: context.l10n.comicDetailLoadFailedRetry,
              onRetry: () => ref.invalidate(comicDetailProvider(comicId)),
            ),
            skipLoadingOnReload: true,
            skipLoadingOnRefresh: true,
          ),
        ),
      ),
    );
  }

  void _handlePopInvoked(BuildContext context, bool didPop) {
    if (didPop) {
      return;
    }
    DetailBackHeader.popOrGoLibrary(
      context,
      locationResolver: resolveComicDetailBackLocationFromContext,
    );
  }
}

class _ComicDetailContent extends ConsumerWidget {
  const _ComicDetailContent({required this.comic});

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

    final ComicDetailViewObject entry = comicDetailEntry(
      comic: comic,
      cover: ComicDetailCover(comicId: comic.comicId),
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
    return ComicDetailLayout(
      entry: entry,
      onBack: () => DetailBackHeader.popOrGoLibrary(
        context,
        locationResolver: resolveComicDetailBackLocationFromContext,
      ),
      onEdit: () => showComicMetadataEdit(context: context, comic: comic),
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
              final navigator = appNavigatorOf(context);
              if (navigator.canPop()) {
                navigator.pop();
              } else {
                goDefaultLibraryBrowseFromContext(context);
              }
            },
          ),
        ),
      ],
      onRead: () => _openReader(ref, incognito: false),
      onReadIncognito: () => _openReader(ref, incognito: true),
      onAuthorTap: (AuthorRef author) => author.hasIdentity
          ? ref.read(openAuthorByIdCommandProvider)(context, author.id!)
          : ref.read(openAuthorByNameCommandProvider)(context, author.name),
      onSeriesSelect: (int index) =>
          _handleSeriesSelect(context, seriesNav, index),
    );
  }

  void _handleSeriesSelect(
    BuildContext context,
    ComicDetailSeriesNavData? seriesNav,
    int index,
  ) {
    final List<ComicDetailSeriesNavItem>? items = seriesNav?.items;
    if (items == null || index < 0 || index >= items.length) {
      return;
    }
    final int current = seriesNav?.currentIndex ?? 0;
    // 同级切卷：只替换当前漫画详情，保留库浏览 → 系列详情 栈。
    // 勿用 go：会清空底层路由，系列返回只能落到 /home。
    appNavigatorOf(context)
        .replaceComicDetail(items[index].comicId, reverse: index < current);
  }

  Future<void> _openReader(WidgetRef ref, {required bool incognito}) =>
      Future<void>.sync(
        () => ref
            .read(appNavigatorProvider)
            .openReader(comicId: comic.comicId, incognito: incognito),
      );

  Future<void> _refreshMetadata(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;
    try {
      await ref.read(refreshComicMetadataCommandProvider)(
        comicId: comic.comicId,
        title: comic.title,
      );
      if (!context.mounted) {
        return;
      }
      showSuccessSnackbar(context, l10n.refreshMetadataComicSuccess);
    } catch (err) {
      if (context.mounted) {
        showErrorSnackbar(context, err);
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
            showErrorSnackbar(context, error);
            return;
          }
          showErrorSnackbar(
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
