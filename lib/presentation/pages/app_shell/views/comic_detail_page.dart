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
import 'package:hentai_library/presentation/widgets/button/ghost_button.dart';
import 'package:hentai_library/presentation/widgets/dialog/edit_metadata_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

const double _kDetailLayoutMaxWidth = 1200;
const double _kDetailTitleLetterSpacing = 0.4;
const double _kDetailNarrowBreakpoint = 720;
const double _kLeftColumnMaxWidth = 300;
const int _kTagsCollapsedMaxCount = 8;

class ComicDetailPage extends HookConsumerWidget {
  final String comicId;

  const ComicDetailPage({super.key, required this.comicId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final rawData = ref.watch(
      libraryPageProvider.select((s) => s.rawComicsAsyncValue),
    );

    return ColoredBox(
      color: cs.winBackground,
      child: rawData.when(
        loading: () => const _ComicDetailLoadingView(),
        error: (error, _) => _ComicDetailErrorView(
          onRetry: () => ref.read(libraryPageProvider.notifier).refreshStream(),
        ),
        data: (comics) {
          final comic = comics.firstWhereOrNull((c) => c.comicId == comicId);
          if (comic == null) {
            return _ComicDetailEmptyView(comicId: comicId);
          }
          return _DetailContent(comic: comic);
        },
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final Comic comic;

  const _DetailContent({required this.comic});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isNarrow = constraints.maxWidth < _kDetailNarrowBreakpoint;
        return _ComicDetailShell(
          isNarrow: isNarrow,
          child: _ComicDetailCard(
            maxWidth: _kDetailLayoutMaxWidth,
            child: Padding(
              padding: EdgeInsets.all(tokens.spacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DetailHeader(comic: comic),
                  SizedBox(height: tokens.spacing.xl),
                  _DetailResponsiveBody(isNarrow: isNarrow, comic: comic)
                      .animate()
                      .fadeIn(duration: 260.ms, curve: Curves.easeOutCubic)
                      .slideY(
                        begin: 0.03,
                        duration: 260.ms,
                        curve: Curves.easeOutCubic,
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailResponsiveBody extends StatelessWidget {
  const _DetailResponsiveBody({required this.isNarrow, required this.comic});

  final bool isNarrow;
  final Comic comic;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kLeftColumnMaxWidth),
              child: _LeftColumn(comic: comic),
            ),
          ),
          SizedBox(height: tokens.spacing.lg + 8),
          _RightColumn(comic: comic),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kLeftColumnMaxWidth),
          child: _LeftColumn(comic: comic),
        ),
        SizedBox(width: tokens.spacing.lg + 16),
        Expanded(child: _RightColumn(comic: comic)),
      ],
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final Comic comic;

  const _DetailHeader({required this.comic});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BackBtn(),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.spacing.md),
                child: Align(
                  alignment: Alignment.center,
                  child: Tooltip(
                    message: comic.title,

                    child: SelectableText(
                      comic.title,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: tokens.text.titleLg,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        letterSpacing: _kDetailTitleLetterSpacing,
                        color: cs.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spacing.md),
        Divider(height: 1, color: cs.outline.withAlpha(100)),
      ],
    );
  }
}

class _LeftColumn extends HookConsumerWidget {
  final Comic comic;

  const _LeftColumn({required this.comic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;

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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(tokens.radius.lg),
              border: Border.all(color: cs.borderSubtle),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: isCoverHover.value
                      ? cs.cardShadowHover
                      : cs.cardShadow,
                  blurRadius: isCoverHover.value ? 6 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: Container(
                color: cs.surfaceContainerHighest,
                child: coverPath != null
                    ? Image.file(File(coverPath), fit: BoxFit.cover)
                          .animate(target: isCoverHover.value ? 1 : 0)
                          .scale(
                            begin: const Offset(1.0, 1.0),
                            end: const Offset(1.05, 1.05),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutQuad,
                          )
                    : Icon(
                        LucideIcons.imageOff,
                        size: 36,
                        color: cs.imageFallback,
                      ),
              ),
            ),
          ),
        ),
        SizedBox(height: tokens.spacing.md),
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
    final AppThemeTokens tokens = context.tokens;
    final List<Widget> statChildren = <Widget>[
      _StatRow(icon: LucideIcons.files, label: '页数', value: pageLabel),
      _StatRow(icon: LucideIcons.package, label: '资源格式', value: formatLabel),
      if (ratingLabel != null)
        _StatRow(icon: LucideIcons.shield, label: '分级', value: ratingLabel),
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
                fontSize: tokens.text.bodySm,
                fontWeight: FontWeight.w500,
                color: cs.textPrimary,
              ),
            ),
          ),
        ),
        SizedBox(height: tokens.spacing.sm + 6),
        _MetadataLabeledRow(
          label: '标签',
          child: _TagsExpandableSection(tags: tags),
        ),
        SizedBox(height: tokens.spacing.lg),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacing.md,
            vertical: tokens.spacing.md,
          ),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withAlpha(120),
            borderRadius: BorderRadius.circular(tokens.radius.md + 2),
            border: Border.all(color: cs.borderSubtle.withAlpha(180)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int i = 0; i < statChildren.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i < statChildren.length - 1 ? tokens.spacing.sm : 0,
                  ),
                  child: statChildren[i],
                ),
            ],
          ),
        ),
        SizedBox(height: tokens.spacing.xl),
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

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  static const double _kStatLabelWidth = 72;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: cs.iconSecondary),
        SizedBox(width: tokens.spacing.sm),
        SizedBox(
          width: _kStatLabelWidth,
          child: Text(
            label,
            style: TextStyle(
              fontSize: tokens.text.labelXs,
              color: cs.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: tokens.text.bodySm,
              color: cs.textSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetadataLabeledRow extends StatelessWidget {
  const _MetadataLabeledRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: tokens.text.labelXs,
            color: cs.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: tokens.spacing.sm - 2),
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
    final AppThemeTokens tokens = context.tokens;
    if (tags.isEmpty) {
      return Text(
        '暂无标签',
        style: TextStyle(fontSize: tokens.text.labelXs, color: cs.textTertiary),
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
          spacing: tokens.spacing.sm,
          runSpacing: tokens.spacing.sm,
          children: shown.map((String e) => _TagChip(text: e)).toList(),
        ),
        if (needsToggle) ...[
          SizedBox(height: tokens.spacing.sm),
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

ButtonStyle _detailPrimaryActionStyle(ThemeData theme, AppThemeTokens tokens) {
  final ColorScheme cs = theme.colorScheme;
  return ElevatedButton.styleFrom(
    backgroundColor: cs.primary,
    foregroundColor: cs.onPrimary,
    elevation: 1,
    padding: EdgeInsets.symmetric(
      horizontal: tokens.spacing.xl,
      vertical: tokens.spacing.sm + 6,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radius.md),
    ),
  );
}

class _DetailPrimaryActions extends HookConsumerWidget {
  const _DetailPrimaryActions({required this.comic});

  final Comic comic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final ButtonStyle primaryStyle = _detailPrimaryActionStyle(theme, tokens);

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: tokens.spacing.md,
        runSpacing: tokens.spacing.sm,
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
                  queryParameters: {
                    'read_type': 'comic',
                    'comic_id': comic.comicId,
                  },
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
            child: GhostButton.icon(
              icon: LucideIcons.pencil,
              tooltip: '编辑元数据',
              semanticLabel: '编辑元数据',
              size: 32,
              onPressed: () {
                showDialog(
                  context: context,
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
    final AppThemeTokens tokens = context.tokens;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.sm + 2,
        vertical: tokens.spacing.sm - 2,
      ),
      decoration: BoxDecoration(
        color: cs.subtleTagBackground,
        borderRadius: BorderRadius.circular(tokens.radius.md),
        border: Border.all(color: cs.borderSubtle),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: tokens.text.labelXs,
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
    final AppThemeTokens tokens = context.tokens;

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
            spacing: tokens.spacing.sm - 2,
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

class _ComicDetailShell extends StatelessWidget {
  const _ComicDetailShell({required this.isNarrow, required this.child});

  final bool isNarrow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? tokens.spacing.lg : tokens.spacing.lg + 8,
        vertical: tokens.spacing.lg + 8,
      ),
      child: Center(child: child),
    );
  }
}

class _ComicDetailCard extends StatelessWidget {
  const _ComicDetailCard({required this.maxWidth, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final BorderRadius radius = BorderRadius.circular(tokens.radius.lg);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: cs.cardShadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: ColoredBox(
            color: cs.surface,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: cs.borderSubtle),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _ComicDetailLoadingView extends StatelessWidget {
  const _ComicDetailLoadingView();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return _ComicDetailStatusView(
      leading: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.primary),
      ),
      label: '加载中…',
    );
  }
}

class _ComicDetailEmptyView extends StatelessWidget {
  const _ComicDetailEmptyView({required this.comicId});

  final String comicId;

  @override
  Widget build(BuildContext context) {
    return _ComicDetailStatusView(
      leading: Icon(
        LucideIcons.bookOpen,
        size: 48,
        color: Theme.of(context).colorScheme.textTertiary,
      ),
      label: '漫画不存在或已移除',
      action: TextButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(LucideIcons.arrowLeft, size: 16),
        label: const Text('返回'),
      ),
    );
  }
}

class _ComicDetailErrorView extends StatefulWidget {
  const _ComicDetailErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  State<_ComicDetailErrorView> createState() => _ComicDetailErrorViewState();
}

class _ComicDetailErrorViewState extends State<_ComicDetailErrorView> {
  bool _retrying = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ComicDetailStatusView(
      leading: Icon(
        LucideIcons.circleAlert,
        size: 48,
        color: theme.colorScheme.textTertiary,
      ),
      label: '加载失败，请重试',
      action: TextButton.icon(
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
    );
  }
}

class _ComicDetailStatusView extends StatelessWidget {
  const _ComicDetailStatusView({
    required this.leading,
    required this.label,
    this.action,
  });

  final Widget leading;
  final String label;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.spacing.xl * 2 + 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: tokens.spacing.lg,
          children: [
            leading,
            Text(
              label,
              style: TextStyle(
                fontSize: tokens.text.bodyMd,
                color: cs.textSecondary,
              ),
            ),
            if (action != null) action!,
          ],
        ),
      ),
    );
  }
}
