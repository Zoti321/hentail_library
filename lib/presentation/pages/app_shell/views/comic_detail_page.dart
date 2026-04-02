import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/domain/entity/reading_history.dart';
import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hentai_library/domain/util/enums.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/routes/routes.dart';
import 'package:hentai_library/presentation/widgets/dialog/edit_metadata_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

const double _kDetailLayoutMaxWidth = 1200;
const double _kDetailNarrowBreakpoint = 720;
const double _kLeftColumnMaxWidth = 300;
const int _kTagsCollapsedMaxCount = 8;

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
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.surface,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isNarrow = constraints.maxWidth < _kDetailNarrowBreakpoint;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 16 : 24,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: _kDetailLayoutMaxWidth,
                ),
                child: Material(
                  color: cs.surface,
                  elevation: 14,
                  shadowColor: Colors.black.withOpacity(0.18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: cs.outline.withAlpha(70)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DetailHeader(comic: comic),
                        const SizedBox(height: 20),
                        if (isNarrow) ...[
                          Align(
                            alignment: Alignment.center,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: _kLeftColumnMaxWidth,
                              ),
                              child: _LeftColumn(comic: comic),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _RightColumn(comic: comic),
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: _kLeftColumnMaxWidth,
                                ),
                                child: _LeftColumn(comic: comic),
                              ),
                              const SizedBox(width: 32),
                              Expanded(child: _RightColumn(comic: comic)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final Comic comic;

  const _DetailHeader({required this.comic});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BackBtn(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Tooltip(
              message: comic.title,
              child: Text(
                comic.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  color: cs.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
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

    final String? coverPath = ref
        .watch(comicCoverPathProvider(comicId: comic.comicId))
        .maybeWhen(data: (String? v) => v, orElse: () => null);

    final isCoverHover = useState<bool>(false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
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
        const SizedBox(height: 12),
      ],
    );
  }
}

class _RightColumn extends HookConsumerWidget {
  const _RightColumn({required this.comic});

  final Comic comic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final int? pageCount = ref
        .watch(comicImagesProvider(comicId: comic.comicId))
        .maybeWhen(
          data: (List<File> files) => files.length,
          orElse: () => comic.pageCount,
        );
    final List<String> tags = comic.tags.map((t) => t.name).toList();
    final String authorsText = comic.authors.isEmpty
        ? '未知'
        : comic.authors.join(' / ');
    final String pageLabel = pageCount == null || pageCount == 0
        ? '未知'
        : '$pageCount 页';
    final String formatLabel = comic.resourceType.name.toUpperCase();
    final String? ratingLabel = _resolveContentRatingLabel(comic.contentRating);
    final List<String> statLines = <String>[
      '页数: $pageLabel',
      '资源格式: $formatLabel',
      if (ratingLabel != null) '分级: $ratingLabel',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _MetadataLabeledRow(
          label: '作者',
          child: Tooltip(
            message: authorsText,
            child: Text(
              authorsText,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: cs.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _MetadataLabeledRow(
          label: '标签',
          child: _TagsExpandableSection(tags: tags),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withAlpha(120),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.borderSubtle.withAlpha(180)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int i = 0; i < statLines.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i < statLines.length - 1 ? 6 : 0,
                  ),
                  child: Text(
                    statLines[i],
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _DetailPrimaryActions(comic: comic),
      ],
    );
  }
}

String? _resolveContentRatingLabel(ContentRating rating) {
  switch (rating) {
    case ContentRating.unknown:
      return null;
    case ContentRating.safe:
      return '全年龄';
    case ContentRating.r18:
      return 'R18';
  }
}

class _MetadataLabeledRow extends StatelessWidget {
  const _MetadataLabeledRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: cs.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _TagsExpandableSection extends HookWidget {
  const _TagsExpandableSection({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final expanded = useState<bool>(false);
    if (tags.isEmpty) {
      return Text(
        '暂无标签',
        style: TextStyle(fontSize: 12, color: cs.textTertiary),
      );
    }
    final bool needsToggle = tags.length > _kTagsCollapsedMaxCount;
    final List<String> shown = needsToggle && !expanded.value
        ? tags.take(_kTagsCollapsedMaxCount).toList()
        : tags;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: shown.map((String e) => _TagChip(text: e)).toList(),
        ),
        if (needsToggle) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => expanded.value = !expanded.value,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(expanded.value ? '收起' : '显示全部'),
          ),
        ],
      ],
    );
  }
}

ButtonStyle _detailPrimaryActionStyle(ThemeData theme) {
  final ColorScheme cs = theme.colorScheme;
  return ElevatedButton.styleFrom(
    backgroundColor: cs.primary,
    foregroundColor: cs.onPrimary,
    elevation: 1,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
}

ButtonStyle _detailSecondaryActionStyle(ThemeData theme) {
  final ColorScheme cs = theme.colorScheme;
  return ElevatedButton.styleFrom(
    backgroundColor: cs.surfaceContainerHighest,
    foregroundColor: cs.primary,
    elevation: 0,
    shadowColor: Colors.transparent,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: cs.outline.withAlpha(140)),
    ),
  );
}

class _DetailPrimaryActions extends HookConsumerWidget {
  const _DetailPrimaryActions({required this.comic});

  final Comic comic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ButtonStyle primaryStyle = _detailPrimaryActionStyle(theme);
    final ButtonStyle secondaryStyle = _detailSecondaryActionStyle(theme);
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
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
              label: const Text('开始阅读'),
              style: primaryStyle,
            ),
          ),
          Semantics(
            label: '编辑元数据',
            button: true,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.transparent,
                  builder: (BuildContext context) => EditMetadataDialog(
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
              icon: Icon(LucideIcons.pencil, size: 16),
              label: const Text('编辑元数据'),
              style: secondaryStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.borderSubtle),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: cs.textPrimary,
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
    final ThemeData theme = Theme.of(context);

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
