part of 'library_page_widgets.dart';

class LibraryPaginationBarSliver extends ConsumerWidget {
  const LibraryPaginationBarSliver({
    super.key,
    required this.target,
    this.placement = LibraryPaginationPlacement.bottom,
  });

  final LibraryDisplayTarget target;
  final LibraryPaginationPlacement placement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryPagination? pagination = switch (target) {
      LibraryDisplayTarget.comics => ref.watch(
        libraryComicsCatalogControllerProvider.select(
          (AsyncValue<LibraryComicsCatalogState> async) =>
              async.value?.pagination,
        ),
      ),
      LibraryDisplayTarget.series => ref.watch(
        librarySeriesCatalogControllerProvider.select(
          (AsyncValue<LibrarySeriesCatalogState> async) =>
              async.value?.pagination,
        ),
      ),
    };
    if (pagination == null || pagination.totalPages <= 1) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: LibraryPaginationBar(
        page: pagination.page,
        totalPages: pagination.totalPages,
        placement: placement,
        onJump: (PageJump jump) =>
            ref.read(libraryPageFacadeProvider.notifier).jumpPage(target, jump),
      ),
    );
  }
}
