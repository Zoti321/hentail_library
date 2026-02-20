import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/domain/entity/entities.dart';
import 'package:hentai_library/domain/enums/enums.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/routes/routes.dart';
import 'package:hentai_library/presentation/widgets/dialog/edit_metadata_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ComicDetailPage extends HookConsumerWidget {
  final String comicId;

  const ComicDetailPage({super.key, required this.comicId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawData = ref.watch(rawDataComicsProvider);

    return rawData.when(
      loading: () => const _DetailLoading(),
      error: (error, _) =>
          _DetailError(onRetry: () => ref.invalidate(rawDataComicsProvider)),
      data: (comics) {
        final comic = comics.firstWhereOrNull((c) => c.id == comicId);
        if (comic == null) {
          return _DetailEmpty(comicId: comicId);
        }
        return _DetailContent(comic: comic);
      },
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
    );
  }
}

class _DetailContent extends StatelessWidget {
  final Comic comic;

  const _DetailContent({required this.comic});

  @override
  Widget build(BuildContext context) {
    final authors = comic.tags
        .where((tag) => tag.type == CategoryTagType.author)
        .toList();
    final characters = comic.tags
        .where((tag) => tag.type == CategoryTagType.character)
        .toList();
    final tags = comic.tags
        .where((tag) => tag.type == CategoryTagType.tag)
        .toList();
    final series = comic.tags
        .where((tag) => tag.type == CategoryTagType.series)
        .toList();

    return SingleChildScrollView(
      padding: const .symmetric(horizontal: 48, vertical: 24),
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: 32,
        children: [
          Container(
            padding: .symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                const _BackBtn(),
                _ComicEditBtn(comic: comic),
              ],
            ),
          ),
          Row(
            spacing: 64,
            crossAxisAlignment: .start,
            children: [
              Flexible(
                flex: 1,
                child: _LeftColumn(
                  comic: comic,
                  pageCount: comic.totalPageCount,
                ),
              ),
              Flexible(
                flex: 2,
                child: _RightColumn(
                  title: comic.title,
                  authors: authors,
                  series: series,
                  tags: tags,
                  characters: characters,
                  date: comic.firstPublishedAt,
                  description: comic.description,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailLoading extends StatelessWidget {
  const _DetailLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            const CircularProgressIndicator(),
            Text(
              '加载中…',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  final VoidCallback onRetry;

  const _DetailError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Icon(
              LucideIcons.circleAlert,
              size: 48,
              color: theme.colorScheme.textTertiary,
            ),
            Text(
              '加载失败，请重试',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.textSecondary,
              ),
            ),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailEmpty extends StatelessWidget {
  final String comicId;

  const _DetailEmpty({required this.comicId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Icon(
              LucideIcons.bookOpen,
              size: 48,
              color: theme.colorScheme.textTertiary,
            ),
            Text(
              '漫画不存在或已移除',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.textSecondary,
              ),
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(LucideIcons.arrowLeft, size: 16),
              label: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftColumn extends HookConsumerWidget {
  final Comic comic;
  final int pageCount;

  const _LeftColumn({required this.comic, required this.pageCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final coverUrl = comic.coverUrl;
    final isCoverHover = useState<bool>(false);

    return Column(
      crossAxisAlignment: .stretch,
      mainAxisSize: .min,
      children: [
        // 1. 封面 (Cover)
        MouseRegion(
          onEnter: (_) => isCoverHover.value = true,
          onExit: (_) => isCoverHover.value = false,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: .circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: .antiAlias,
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: coverUrl != null
                    ? Image.file(File(coverUrl), fit: .cover)
                          .animate(target: isCoverHover.value ? 1 : 0)
                          .scale(
                            begin: Offset(1.0, 1.0),
                            end: Offset(1.05, 1.05),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutQuad,
                          )
                    : const Icon(Icons.broken_image, size: 36),
              ),
            ),
          ),
        ),
        const SizedBox(height: 36),

        // 2. 操作按钮 (Actions)
        Semantics(
          label: '开始阅读',
          button: true,
          child: ElevatedButton.icon(
            onPressed: () async {
              await ref.read(incrementReadCountUseCaseProvider).call(comic.id);
              await ref
                  .read(recordReadingProgressUseCaseProvider)
                  .call(
                    ReadingHistory(
                      comicId: comic.id,
                      title: comic.title,
                      coverUrl: comic.coverUrl,
                      lastReadTime: DateTime.now(),
                    ),
                  );
              appRouter.pushNamed('阅读页面', pathParameters: {'id': comic.id});
            },
            icon: Icon(LucideIcons.play, size: 16),
            label: Text("开始阅读"),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 3. 技术参数
        Container(
          padding: .all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.colorScheme.borderSubtle),
            borderRadius: .circular(8),
          ),
          child: Column(
            spacing: 8,
            children: [
              _StatRow(
                icon: LucideIcons.stickyNote,
                label: "页数",
                value: "$pageCount p",
              ),
              _StatRow(
                icon: LucideIcons.bookMarked,
                label: "Format",
                value: "Folder",
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RightColumn extends StatelessWidget {
  final String title;
  final String? description;
  final List<CategoryTag> authors;
  final List<CategoryTag> series;
  final List<CategoryTag> characters;
  final List<CategoryTag> tags;
  final DateTime? date;

  const _RightColumn({
    this.date,
    required this.title,
    this.description,
    required this.authors,
    required this.series,
    required this.characters,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      children: [
        // 1. 头部信息 (Header)
        if (date != null)
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: theme.colorScheme.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                date.toString(),
                style: TextStyle(
                  color: theme.colorScheme.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.1,
            color: theme.colorScheme.textPrimary,
          ),
        ),
        const SizedBox(height: 32),

        // 2. 信息网格
        _InfoSection(
          title: "作者: ",
          icon: LucideIcons.penTool,
          chips: authors.map((e) => e.name).toList(),
        ),
        _InfoSection(
          title: "系列: ",
          icon: LucideIcons.library,
          chips: series.map((e) => e.name).toList(),
        ),
        _InfoSection(
          title: "登场人物: ",
          icon: LucideIcons.users,
          chips: characters.map((e) => e.name).toList(),
        ),
        _InfoSection(
          title: "标签: ",
          icon: LucideIcons.tag,
          chips: tags.map((e) => e.name).toList(),
        ),

        const SizedBox(height: 24),
        Divider(color: theme.colorScheme.borderSubtle),
        const SizedBox(height: 24),

        // 3. 简介
        Row(
          children: [
            Icon(
              LucideIcons.bookOpen,
              size: 16,
              color: theme.colorScheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              "简介",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          description ?? '暂无',
          style: TextStyle(color: theme.colorScheme.textSecondary, height: 1.5),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.textTertiary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> chips;

  const _InfoSection({
    required this.title,
    required this.icon,
    required this.chips,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: .start,
      children: [
        Padding(
          padding: const .symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 14, color: theme.colorScheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.0,
                  color: theme.colorScheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips.map((e) => _ChipPlaceholder(text: e)).toList(),
        ),
      ],
    );
  }
}

class _ChipPlaceholder extends StatelessWidget {
  final String text;
  const _ChipPlaceholder({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.colorScheme.borderSubtle),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _BackBtn extends HookWidget {
  const _BackBtn();

  @override
  Widget build(BuildContext context) {
    final useBackBtnHover = useState<bool>(false);
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => useBackBtnHover.value = true,
      onExit: (_) => useBackBtnHover.value = false,
      child: Semantics(
        label: '返回漫画库',
        button: true,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Row(
            spacing: 6,
            children: [
              Icon(LucideIcons.arrowLeft, size: 18)
                  .animate(target: useBackBtnHover.value ? 1 : 0)
                  .tint(duration: 200.ms, color: theme.colorScheme.primary),
              Text("回到漫画库")
                  .animate(target: useBackBtnHover.value ? 1 : 0)
                  .tint(duration: 200.ms, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComicEditBtn extends HookConsumerWidget {
  const _ComicEditBtn({required this.comic});

  final Comic comic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useEditBtnHover = useState<bool>(false);
    final theme = Theme.of(context);

    return Tooltip(
      message: '编辑元数据',
      child: Semantics(
        label: '编辑元数据',
        button: true,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => useEditBtnHover.value = true,
          onExit: (_) => useEditBtnHover.value = false,
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => EditMetadataDialog(
                  comic: comic,
                  onSave: (data) async {
                    await ref.read(updateComicMetadataUseCaseProvider)(
                      comic.id,
                      data,
                    );
                  },
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: .all(8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  width: 1,
                  color: useEditBtnHover.value
                      ? theme.colorScheme.borderSubtle
                      : theme.colorScheme.borderSubtle.withAlpha(0),
                ),
              ),
              child: Icon(
                LucideIcons.pencil,
                size: 14,
                color: theme.colorScheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
