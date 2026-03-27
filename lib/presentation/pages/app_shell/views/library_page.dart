import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/core/l10n/app_strings.dart';
import 'package:hentai_library/domain/entity/comic/library_comic.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/routes/routes.dart';
import 'package:hentai_library/presentation/widgets/button/filter_popup_button.dart';
import 'package:hentai_library/presentation/widgets/button/sort_popup_button.dart';
import 'package:hentai_library/presentation/widgets/card_item/comic_card.dart';
import 'package:hentai_library/presentation/widgets/card_item/comic_tile.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  bool _isGridView = true;

  AsyncValue<List<LibraryComic>> comics = const AsyncValue.loading();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    comics = ref.watch(processLibraryComicsProvider);

    final comicCount = comics.when(
      data: (data) => data.length,
      error: (err, stack) => 0,
      loading: () => 0,
      skipLoadingOnReload: true,
    );

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: .spaceBetween,
              spacing: 36,
              children: [
                // 标题行
                Row(
                  crossAxisAlignment: .center,
                  children: [
                    Text(
                      AppStrings.libraryTitle,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        AppStrings.comicCount(comicCount),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                // Windows 11 风格工具栏
                _buildToolbar(theme),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: .symmetric(horizontal: 24, vertical: 16),
          sliver: _isGridView ? _buildGridView() : _buildListView(),
        ),
      ],
    );
  }

  Widget _buildToolbar(ThemeData theme) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          // 搜索框
          Container(
            constraints: BoxConstraints(maxWidth: 164),
            child: TextField(
              onChanged: (val) =>
                  ref.read(comicFilterProvider.notifier).updateQuery(val),
              textAlignVertical: TextAlignVertical.center,
              cursorWidth: 1.0,
              cursorColor: Colors.black87,
              cursorHeight: 14.5,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(
                  LucideIcons.search,
                  size: 18,
                  color: Colors.grey,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                hintText: "搜索...",
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: .w400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          // 垂直分割线
          Container(
            width: 1,
            height: 20,
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          // 功能按钮组 (Refresh, Filter, Sort)
          _ToolbarIconButton(
            icon: LucideIcons.rotateCw,
            tooltip: "刷新",
            onPressed: () {
              ref.invalidate(rawDataComicsProvider);
            },
          ),
          const SizedBox(width: 8),
          FilterPopupButton(),
          const SizedBox(width: 8),
          SortPopupButton(),
          // 垂直分割线
          Container(
            width: 1,
            height: 20,
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),

          // 视图切换 (Grid/List)
          Row(
            children: [
              _ViewToggleButton(
                icon: LucideIcons.layoutGrid,
                isActive: _isGridView,
                onTap: () => setState(() => _isGridView = true),
                activeColor: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              _ViewToggleButton(
                icon: LucideIcons.list,
                isActive: !_isGridView,
                onTap: () => setState(() => _isGridView = false),
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建网格视图
  Widget _buildGridView() {
    return comics.when(
      data: (comics) {
        if (comics.isEmpty) return _EmptyLibrarySliver();
        return SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            mainAxisExtent: 356,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: comics.length,
          itemBuilder: (context, index) {
            final manga = comics[index];
            return Center(
              child: ComicCard(
                key: Key(manga.comicId),
                comic: manga,
                size: Size(double.infinity, double.infinity),
                onTap: () {
                  appRouter.pushNamed(
                    '漫画详情',
                    pathParameters: {'id': manga.comicId},
                  );
                },
                onPlay: () {},
                onRightClick: (val) {},
              ),
            );
          },
        );
      },
      error: (err, stack) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $err'),
        ),
      ),
      loading: () => SliverToBoxAdapter(
        child: const Center(child: CircularProgressIndicator()),
      ),
      skipLoadingOnReload: true,
    );
  }

  // 构建列表视图
  Widget _buildListView() {
    return comics.when(
      data: (comics) {
        if (comics.isEmpty) return _EmptyLibrarySliver();
        return SliverList.separated(
          itemCount: comics.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final manga = comics[index];
            return ComicTile(
              key: Key(manga.comicId),
              comic: manga,
              onTap: () {
                appRouter.pushNamed(
                  '漫画详情',
                  pathParameters: {'id': manga.comicId},
                );
              },
              onRightClick: (val) {},
            );
          },
        );
      },
      error: (err, stack) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $err'),
        ),
      ),
      loading: () => SliverFillRemaining(
        hasScrollBody: false,
        child: const Center(child: CircularProgressIndicator()),
      ),
      skipLoadingOnReload: true,
    );
  }
}

class _EmptyLibrarySliver extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              Icon(
                LucideIcons.library,
                size: 56,
                color: theme.colorScheme.textTertiary,
              ),
              Text(
                AppStrings.libraryEmptyTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.textPrimary,
                ),
              ),
              Text(
                AppStrings.libraryEmptyHint,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 16, color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;

  const _ViewToggleButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 0),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isActive ? Colors.grey[100] : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isActive ? activeColor : Colors.grey[500],
          ),
        ),
      ),
    );
  }
}
