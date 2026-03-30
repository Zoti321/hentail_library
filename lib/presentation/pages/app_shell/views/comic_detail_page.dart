import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/domain/entity/reading_history.dart';
import 'package:hentai_library/domain/entity/comic/comic.dart';
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
    final rawData = ref.watch(
      libraryPageProvider.select((s) => s.rawComicsAsyncValue),
    );

    return rawData.when(
      loading: () => const _DetailLoading(),
      error: (error, _) => _DetailError(
        onRetry: () => ref.read(libraryPageProvider.notifier).refreshStream(),
      ),
      data: (comics) {
        final comic = comics.firstWhereOrNull((c) => c.comicId == comicId);
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 32,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _BackBtn(),
                _ComicEditBtn(comic: comic),
              ],
            ),
          ),
          Row(
            spacing: 64,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(flex: 1, child: _LeftColumn(comic: comic)),
              Flexible(
                flex: 2,
                child: _RightColumn(
                  title: comic.title,
                  authors: comic.authors,
                  tags: comic.tags.map((t) => t.name).toList(),
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

class _DetailError extends StatefulWidget {
  final VoidCallback onRetry;

  const _DetailError({required this.onRetry});

  @override
  State<_DetailError> createState() => _DetailErrorState();
}

class _DetailErrorState extends State<_DetailError> {
  bool _retrying = false;

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
              onPressed: _retrying
                  ? null
                  : () {
                      setState(() => _retrying = true);
                      widget.onRetry();
                    },
              icon: _retrying
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(_retrying ? '重试中…' : '重试'),
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

  const _LeftColumn({required this.comic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final coverPath = ref
        .watch(comicCoverPathProvider(comicId: comic.comicId))
        .maybeWhen(data: (v) => v, orElse: () => null);
    final pageCount = ref
        .watch(comicImagesProvider(comicId: comic.comicId))
        .maybeWhen(data: (files) => files.length, orElse: () => 0);

    final isCoverHover = useState<bool>(false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. 封面 (Cover)
        MouseRegion(
          onEnter: (_) => isCoverHover.value = true,
          onExit: (_) => isCoverHover.value = false,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: coverPath != null
                    ? Image.file(File(coverPath), fit: BoxFit.cover)
                          .animate(target: isCoverHover.value ? 1 : 0)
                          .scale(
                            begin: const Offset(1.0, 1.0),
                            end: const Offset(1.05, 1.05),
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
              await ref
                  .read(recordReadingProgressUseCaseProvider)
                  .call(
                    ReadingHistory(
                      comicId: comic.comicId,
                      title: comic.title,
                      lastReadTime: DateTime.now(),
                    ),
                  );
              appRouter.pushNamed(
                '阅读页面',
                pathParameters: {'id': comic.comicId},
              );
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.colorScheme.borderSubtle),
            borderRadius: BorderRadius.circular(8),
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
                value: comic.resourceType.name,
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
  final List<String> authors;
  final List<String> tags;

  const _RightColumn({
    required this.title,
    required this.authors,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.1,
            color: theme.colorScheme.textPrimary,
          ),
        ),
        const SizedBox(height: 32),

        _InfoSection(title: "作者: ", icon: LucideIcons.penTool, chips: authors),
        _InfoSection(title: "标签: ", icon: LucideIcons.tag, chips: tags),

        const SizedBox(height: 24),
        Divider(color: theme.colorScheme.borderSubtle),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
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
                      comic.comicId,
                      data,
                    );
                  },
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
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
